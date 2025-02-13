// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPancakePair.sol";
import "./PancakePair.sol";

contract PancakeFactory is Ownable, ReentrancyGuard {
    // Events
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    // State variables
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    // Protocol fee settings
    address public feeTo;
    address public feeToSetter;
    
    // INIT_CODE_PAIR_HASH is used for pair address creation
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(PancakePair).creationCode));

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    // Returns the number of pairs created
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    // Creates a new pair for two tokens
    function createPair(address tokenA, address tokenB) external nonReentrant returns (address pair) {
        require(tokenA != tokenB, "PancakeFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "PancakeFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PancakeFactory: PAIR_EXISTS");

        // Create new pair contract
        bytes memory bytecode = type(PancakePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IPancakePair(pair).initialize(token0, token1);

        // Store the pair addresses
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // Sets the fee recipient
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "PancakeFactory: FORBIDDEN");
        feeTo = _feeTo;
    }

    // Sets the fee setter address
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "PancakeFactory: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
} 