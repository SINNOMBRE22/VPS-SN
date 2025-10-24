#!/bin/bash
key_word=$(wget --no-check-certificate -t3 -T5 -qO- "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN/vercion")
echo "${key_word}" > /etc/VPS-SN/new_vercion && chmod +x /etc/VPS-SN/new_vercion
