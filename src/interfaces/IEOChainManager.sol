// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IEOChainManager {
    event DataValidatorRegistered(address indexed operator, uint96[] stakes, bytes quorumNumbers);
    event ChainValidatorRegistered(address indexed operator, uint96[] stakes, bytes quorumNumbers);
    event OperatorUpdated(address indexed operator, uint96[] stakes, bytes quorumsToUpdate);
    event ValidatorDeregistered(address indexed operator);

    /// @notice Registers a new data validator
    /// @param operator The address of the operator to register as a data validator
    /// @param stakes An array of stake amounts
    /// @param quorumNumbers An array of quorum numbers to register the operator in
    function registerDataValidator(address operator, uint96[] calldata stakes, bytes calldata quorumNumbers) external;

    /// @notice Registers a new chain validator
    /// @param operator The address of the operator to register as a chain validator
    /// @param stakes An array of stake amounts
    /// @param signature A 2-element array representing a signature
    /// @param pubkey A 4-element array representing a public key
    /// @param quorumNumbers An array of quorum numbers to register the operator in
    function registerChainValidator(
        address operator,
        uint96[] calldata stakes,
        uint256[2] memory signature,
        uint256[4] memory pubkey,
        bytes calldata quorumNumbers
    ) external;

    /// @notice Deregisters a validator (data validators only)
    /// @param operator The address of the operator to deregister
    /// @param quorumNumbers An array of quorum numbers to deregister the operator from
    function deregisterValidator(address operator, bytes calldata quorumNumbers) external;

    /// @notice Updates the stake weights of a validator
    /// @param operator The address of the operator to update
    /// @param newStakeWeights An array of new stake amounts
    /// @param quorumsToUpdate An array of quorums related to operator and used for update
    function updateOperator(address operator, uint96[] calldata newStakeWeights, bytes calldata quorumsToUpdate) external;
}
