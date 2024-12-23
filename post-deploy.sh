#!/bin/bash

echo "Exporting deployment files & ABIs"

cp ./out/LLMOracleCoordinator.sol/LLMOracleCoordinator.json ./deployments/abis/LLMOracleCoordinator.json
node ./deployments/abis/parseAbi.cjs ./deployments/abis/LLMOracleCoordinator.json

cp ./out/LLMOracleRegistry.sol/LLMOracleRegistry.json ./deployments/abis/LLMOracleRegistry.json
node ./deployments/abis/parseAbi.cjs ./deployments/abis/LLMOracleRegistry.json

