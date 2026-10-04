from web3 import Web3
from decimal import Decimal
import secrets
import time
from eth_account import Account
from lottery import Lottery
from typing import Optional, Dict, Tuple

# How long a freshly minted ticket stays claimable (packed into packed1[225,256)
# as a uint31 delta from `issued`). The recipient must claim winners before this
# elapses or they become worthless on-chain, so it has to comfortably exceed the
# claim worker's batching window (max_wait_seconds, default 1h) plus any downtime.
# A week gives a large margin; the funder's escrow stays liable for that face for
# the window, so it is a funder-vs-recipient tradeoff. ⚠ REVIEW production value.
DEFAULT_EXPIRE_SECONDS = 7 * 24 * 3600
UINT31_MAX = (1 << 31) - 1

class OrchidAccountError(Exception):
    """Base class for Orchid account errors"""
    pass

class InvalidAddressError(OrchidAccountError):
    """Invalid Ethereum address"""
    pass

class InvalidAmountError(OrchidAccountError):
    """Invalid payment amount"""
    pass

class SigningError(OrchidAccountError):
    """Error signing transaction or message"""
    pass

class OrchidAccount:
    def __init__(self, 
                 lottery: Lottery,
                 funder_address: str,
                 private_key: str):
        try:
            self.lottery = lottery
            self.web3 = lottery.web3
            self.funder = self.web3.to_checksum_address(funder_address)
            self.key = private_key
            self.signer = self.web3.eth.account.from_key(private_key).address
        except ValueError as e:
            raise InvalidAddressError(f"Invalid address format: {e}")
        except Exception as e:
            raise OrchidAccountError(f"Failed to initialize account: {e}")

    def create_ticket(self,
                     amount: int,
                     recipient: str,
                     commitment: str,
                     token_addr: str = "0x0000000000000000000000000000000000000000",
                     win_prob: float = 1.0,
                     face: Optional[int] = None,
                     expire_delta_seconds: int = DEFAULT_EXPIRE_SECONDS,
                     issued: Optional[int] = None
                     ) -> str:
        """
        Create a signed nanopayment ticket worth ``amount`` in expected value.

        A ticket pays its ``face`` value with probability ``win_prob`` and nothing
        otherwise, so EV = face x win_prob. To transfer ``amount`` of value we mint
        face = amount / win_prob at win ratio ~= win_prob*2^64 (Fork A1). The
        recipient credits the EV at handoff and only claims winners on-chain, so
        most tickets never touch the chain — the point of probabilistic payments.

        Args:
            amount: Expected value to transfer, in wei (the invoice amount).
            recipient: Recipient address.
            commitment: Server-chosen commitment hash (keccak(reveal)).
            token_addr: Token contract address.
            win_prob: Win probability in (0, 1]. 1.0 = a guaranteed-win ticket with
                face == amount (the legacy behaviour). Smaller p => larger face,
                rarer wins, fewer on-chain claims, more per-ticket variance. NOTE:
                face = amount/p must be backed by the funder's escrow (a winner
                claims the full face), so p is bounded below by amount/escrow.
                Ignored when ``face`` is given.
            face: Exact face value in wei (Workstream C). When provided, ``win_prob``
                is ignored and the win ratio is solved so the booked EV matches the
                invoice: ratio = (amount<<64)//face - 1, giving EV = face*(ratio+1)/
                2^64 <= amount (the floor favours the recipient). The client sizes
                face = escrow//2 (the funder's collateral) so a winner's full face is
                always backed by >= 2x at-risk collateral (DESIGN-DECISIONS D10).
                Must satisfy amount <= face <= uint128.
            expire_delta_seconds: How long the ticket stays claimable, as a uint31
                delta from ``issued`` (default one week). Clamped to uint31.
            issued: Unix timestamp to stamp as the mint time (default now). Exposed
                for deterministic tests / replay; production should leave it None.

        Returns:
            Serialized ticket string.
        """
        try:
            if amount <= 0:
                raise InvalidAmountError("Amount must be positive")

            recipient = self.web3.to_checksum_address(recipient)
            token_addr = self.web3.to_checksum_address(token_addr)

            UINT64_MAX = (1 << 64) - 1
            UINT128_MAX = (1 << 128) - 1
            if face is not None:
                # Exact-integer face path (Workstream C): the client picks face from
                # the funder's escrow (face = escrow//2) and we solve for the ratio
                # that makes the booked EV == amount. is_winner uses P(win) =
                # (ratio+1)/2^64, so ratio = floor(amount*2^64 / face) - 1 and the
                # EV = face*(ratio+1)/2^64 <= amount (the floor favours the recipient).
                face = int(face)
                if face < amount:
                    raise InvalidAmountError(
                        f"face {face} < amount {amount}: EV target unreachable at P<=1")
                if face > UINT128_MAX:
                    raise InvalidAmountError(f"face {face} exceeds uint128")
                ratio = (amount << 64) // face - 1
                if not (0 <= ratio <= UINT64_MAX):
                    raise InvalidAmountError(
                        f"face {face} yields out-of-range win ratio {ratio} "
                        f"for amount {amount}")
            else:
                if not (0 < win_prob <= 1):
                    raise InvalidAmountError("win_prob must be in (0, 1]")
                # Derive face value and win ratio from the EV target. is_winner uses
                # P(win) = (ratio+1)/2^64, so ratio = round(p*2^64) - 1 and the EV the
                # recipient books, face*(ratio+1)/2^64, comes back to ~= amount.
                if win_prob >= 1.0:
                    ratio = UINT64_MAX                   # guaranteed win, face == amount
                    face = int(amount)
                else:
                    ratio = max(0, min(UINT64_MAX, round(win_prob * (1 << 64)) - 1))
                    face = round(amount / win_prob)
                if face <= 0:
                    raise InvalidAmountError("Computed face value must be positive")
                if face > UINT128_MAX:
                    raise InvalidAmountError(
                        f"Computed face value {face} exceeds uint128 (win_prob too small "
                        f"for amount {amount})")

            # Pack ticket data to the contract's bit layout (lottery1.sol claim_):
            #   packed0: [0,128) face | [128,192) nonce(64) | [192,256) issued(64)
            #   packed1: bit0 v | [1,161) funder | [161,225) ratio(64) | [225,256) expire_delta(31)
            # The signature covers packed0 and packed1>>1, so funder/issued/expiry
            # are all signed — the recipient reads them from the ticket, not from us.
            nonce = secrets.randbits(64)
            issued = int(time.time()) if issued is None else int(issued)
            expire_delta = max(0, min(UINT31_MAX, int(expire_delta_seconds)))
            funder_int = int(self.funder, 16)            # 160-bit address -> [1,161)

            packed0 = (face & ((1 << 128) - 1)) | (nonce << 128) | (issued << 192)
            packed1 = (funder_int << 1) | (ratio << 161) | (expire_delta << 225)  # v=0

            # Sign ticket
            message_hash = self._get_ticket_hash(
                token_addr,
                recipient, 
                commitment,
                packed0,
                packed1
            )
            
            # Sign the digest RAW. The EIP-191 v0 (intended-validator) envelope is
            # already inside message_hash (it begins 0x19 0x00 <lottery addr> ...),
            # and the contract recovers with ecrecover(digest, v, r, s) directly —
            # so we must NOT wrap it again in the personal_sign ("\x19Ethereum
            # Signed Message") envelope (encode_defunct), or on-chain recovery fails.
            sig = Account.unsafe_sign_hash(message_hash, private_key=self.key)

            # Adjust v and update packed1
            v = sig.v - 27
            packed1 = packed1 | v
            
            # Format as hex strings
            return (
                hex(packed0)[2:].zfill(64) +
                hex(packed1)[2:].zfill(64) +
                hex(sig.r)[2:].zfill(64) +
                hex(sig.s)[2:].zfill(64)
            )
            
        except OrchidAccountError:
            raise
        except Exception as e:
            raise SigningError(f"Failed to create ticket: {e}")

    def _get_ticket_hash(self,
                        token_addr: str,
                        recipient: str,
                        commitment: str,
                        packed0: int,
                        packed1: int) -> bytes:
        try:
            return Web3.solidity_keccak(
                ['bytes1', 'bytes1', 'address', 'bytes32', 'address', 'address',
                 'bytes32', 'uint256', 'uint256', 'bytes32'],
                [b'\x19', b'\x00',
                 self.lottery.contract_addr,
                 self.lottery.chain_id.to_bytes(32, 'big'),  # chainid() of the deployed lottery
                 token_addr,
                 recipient,
                 commitment,  # = keccak(reveal); contract hashes reveal once, so embed directly
                 packed0,
                 packed1 >> 1,  # Remove v
                 b'\x00' * 32]  # Empty data field
            )
        except Exception as e:
            raise SigningError(f"Failed to create message hash: {e}")

    async def get_balance(self,
                         token_addr: str = "0x0000000000000000000000000000000000000000"
                         ) -> Tuple[float, float]:
        try:
            balance, escrow = await self.lottery.check_balance(
                token_addr,
                self.funder,
                self.signer
            )
            return (
                self.lottery.wei_to_token(balance),
                self.lottery.wei_to_token(escrow)
            )
        except Exception as e:
            raise OrchidAccountError(f"Failed to get balance: {e}")

    async def get_balance_wei(self,
                              token_addr: str = "0x0000000000000000000000000000000000000000"
                              ) -> Tuple[int, int]:
        """Raw on-chain ``(balance_wei, escrow_wei)`` — the spendable balance and
        the at-risk collateral (escrow), as unrounded integer wei. The client sizes
        a ticket's face off the escrow (face = escrow//2, DESIGN-DECISIONS D10), so
        it needs exact wei here rather than the token-floats ``get_balance`` returns."""
        try:
            return await self.lottery.check_balance(
                token_addr, self.funder, self.signer)
        except Exception as e:
            raise OrchidAccountError(f"Failed to get balance: {e}")
