# Orchid GenAI Server

This repository contains the components for running an AI model inference server with Orchid nanopayments integration. The system consists of three main components:

- A billing server that handles WebSocket connections and payment processing
- An inference API that provides a REST interface for model inference
- A CLI client for testing and interacting with the service

## CLI Client

The CLI client provides a flexible way to interact with the GenAI service, supporting both payment handling and inference requests. It can be run in three modes:

- Normal mode: Handles both payments and inference
- Wallet-only mode: Just handles payments
- Inference-only mode: Just makes inference requests using an existing auth token

### Configuration

The client uses a JSON configuration file with the following structure:

```json
{
  "inference": {
    "provider": "default",
    "funder": "0x...",
    "secret": "your-wallet-secret",
    "chainid": 1,
    "rpc": "https://your-eth-rpc-endpoint"
  },
  "location": {
    "providers": {
      "default": {
        "billing_url": "wss://billing-endpoint"
      }
    }
  },
  "test": {
    "messages": [
      {
        "role": "user",
        "content": "Hello, how are you?"
      }
    ],
    "model": "model-id",
    "params": {
      "temperature": 0.7
    },
    "retry_delay": 1.5
  },
  "logging": {
    "level": "INFO",
    "file": "client.log"
  }
}
```

#### Configuration Sections

- `inference`: Wallet and chain configuration
  - `provider`: Provider ID matching an entry in the location config
  - `funder`: Ethereum address of the funding wallet
  - `secret`: Private key for the funding wallet
  - `chainid`: Ethereum chain ID
  - `rpc`: Ethereum RPC endpoint URL
  - `currency`: (Optional) Currency for payments

- `location`: Service endpoint configuration
  - `providers`: Map of provider IDs to their connection details
    - `billing_url`: WebSocket URL for the billing server

- `test`: Test configuration for inference requests
  - `messages`: Array of chat messages to send
  - `model`: Model ID to use for inference
  - `params`: Additional model parameters
  - `retry_delay`: Delay between retries on insufficient balance

- `logging`: Logging configuration
  - `level`: Log level (DEBUG, INFO, WARNING, ERROR)
  - `file`: Optional log file path

### Usage

Basic usage:

```bash
python client.py config.json
```

Wallet-only mode (just handle payments):

```bash
python client.py config.json --wallet
```

Inference-only mode (using existing auth token):

```bash
python client.py config.json --inference --url "https://inference-url" --key "auth-token"
```

Override prompt from config:

```bash
python client.py config.json "Your prompt here"
```

## Server Components

### Billing Server

The billing server handles WebSocket connections from clients, processes Orchid nanopayments, and maintains client balances. More details coming soon.

### Inference API 

The inference API provides a REST interface for model inference requests, compatible with the OpenAI API format. It integrates with various model providers and handles usage-based billing. More details coming soon.

## Development

Details on setup, contributing, and deployment coming soon.
