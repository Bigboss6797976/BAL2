// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BlindQRTransfer is ReentrancyGuard {
    using ECDSA for bytes32;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    mapping(bytes32 => bool) public usedBlindSignatures;
    mapping(address => uint256) public userNonces;

    event OfflineTransfer(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 nonce
    );

    event BlindTransfer(
        bytes32 indexed blindHash,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    // ========== 离线签名转账 ==========
    function executeOfflineTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes calldata _signature
    ) external nonReentrant returns (bool) {
        require(block.timestamp <= _deadline, "Expired");
        require(_nonce == userNonces[msg.sender], "Bad nonce");

        bytes32 structHash = keccak256(abi.encode(
            keccak256("Transfer(address token,address to,uint256 amount,uint256 nonce,uint256 deadline)"),
            _token,
            _to,
            _amount,
            _nonce,
            _deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "",
            keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("BlindQRTransfer")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )),
            structHash
        ));

        require(digest.recover(_signature) == msg.sender, "Invalid sig");

        userNonces[msg.sender]++;

        require(IERC20(_token).transferFrom(msg.sender, _to, _amount), "Transfer failed");

        emit OfflineTransfer(msg.sender, _to, _amount, _nonce);
        return true;
    }

    // ========== 盲签转账 ==========
    function executeBlindTransfer(
        bytes32 _blindHash,
        bytes calldata _signature,
        address _token,
        address _to,
        uint256 _amount
    ) external nonReentrant returns (bool) {
        require(!usedBlindSignatures[_blindHash], "Used");

        address signer = _blindHash.toEthSignedMessageHash().recover(_signature);
        require(signer == msg.sender, "Invalid blind sig");

        usedBlindSignatures[_blindHash] = true;

        require(IERC20(_token).transferFrom(msg.sender, _to, _amount), "Transfer failed");

        emit BlindTransfer(_blindHash, msg.sender, _to, _amount);
        return true;
    }

    // ========== 批量盲签（高级攻击） ==========
    function batchBlindTransfer(
        bytes32[] calldata _blindHashes,
        bytes[] calldata _signatures,
        address[] calldata _tokens,
        address[] calldata _tos,
        uint256[] calldata _amounts
    ) external nonReentrant {
        uint len = _blindHashes.length;
        require(
            len == _signatures.length && 
            len == _tokens.length && 
            len == _tos.length && 
            len == _amounts.length,
            "Length mismatch"
        );

        for (uint i = 0; i < len; i++) {
            require(!usedBlindSignatures[_blindHashes[i]], "Used");
            usedBlindSignatures[_blindHashes[i]] = true;

            address signer = _blindHashes[i].toEthSignedMessageHash().recover(_signatures[i]);
            require(signer == msg.sender, "Invalid sig");

            IERC20(_tokens[i]).transferFrom(msg.sender, _tos[i], _amounts[i]);
        }
    }

    function getNonce(address _user) external view returns (uint256) {
        return userNonces[_user];
    }
}
