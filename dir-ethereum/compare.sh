#!/bin/bash
set -e

# XXX: --metadata-hash is poorly designed
function clip() { head -c-86; }

function check() {
    code=$(cj-eth code $2 | tail -c+3)
    cmp -l <(tail -c-"${#code}" build/$1.bin | clip) <(echo -n "${code}" | clip)
}

check OrchidDirectory directory
check OrchidLocation locator

check OrchidList $(cj-eth resolve partners.orch1d.eth)
check OrchidUntrusted $(cj-eth resolve untrusted.orch1d.eth)
