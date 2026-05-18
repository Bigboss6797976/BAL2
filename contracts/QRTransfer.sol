// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract QRTransfer is ReentrancyGuard {
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    event QRScanned(address indexed scanner, address indexed recipient, uint256 amount);
    event TransferExecuted(address indexed from, address indexed to, uint256 amount, bytes32 txHash);

    mapping(address => ScanRecord[]) public scanHistory;

    struct ScanRecord {
        address recipient;
        uint256 amount;
        uint256 timestamp;
        bool executed;
        bytes32 txHash;
    }

    function scanQR(address _recipient, uint256 _amount) external returns (uint256 scanId) {
        require(_recipient != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");

        scanId = scanHistory[msg.sender].length;
        scanHistory[msg.sender].push(ScanRecord({
            recipient: _recipient,
            amount: _amount,
            timestamp: block.timestamp,
            executed: false,
            txHash: bytes32(0)
        }));

        emit QRScanned(msg.sender, _recipient, _amount);
        return scanId;
    }

    function executeQRTransfer(uint256 _scanId, uint256 _amount) external nonReentrant returns (bool) {
        require(_scanId < scanHistory[msg.sender].length, "Invalid scan ID");
        ScanRecord storage record = scanHistory[msg.sender][_scanId];
        require(!record.executed, "Already executed");
        require(_amount <= record.amount, "Amount exceeds scanned amount");

        IERC20 usdt = IERC20(USDT);
        uint256 balance = usdt.balanceOf(msg.sender);
        require(balance >= _amount, "Insufficient USDT balance");

        uint256 allowance = usdt.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");

        bool success = usdt.transferFrom(msg.sender, record.recipient, _amount);
        require(success, "Transfer failed");

        record.executed = true;
        record.amount = _amount;
        record.txHash = keccak256(abi.encodePacked(msg.sender, block.timestamp, _amount));

        emit TransferExecuted(msg.sender, record.recipient, _amount, record.txHash);
        return true;
    }

    function quickTransfer(address _recipient, uint256 _amount) external nonReentrant returns (bool) {
        IERC20 usdt = IERC20(USDT);
        require(usdt.transferFrom(msg.sender, _recipient, _amount), "Transfer failed");

        emit TransferExecuted(msg.sender, _recipient, _amount, keccak256(abi.encodePacked(msg.sender, block.number)));
        return true;
    }

    function getScanHistory(address _user) external view returns (ScanRecord[] memory) {
        return scanHistory[_user];
    }

    function getUSDTBalance(address _user) external view returns (uint256) {
        return IERC20(USDT).balanceOf(_user);
    }

    function getAllowance(address _owner) external view returns (uint256) {
        return IERC20(USDT).allowance(_owner, address(this));
    }
}
