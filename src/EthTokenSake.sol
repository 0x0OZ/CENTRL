// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHTokenSale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public saleToken;
    uint256 public rate; // Ensure this rate considers the desired conversion accurately
    uint256 public start;
    uint256 public end;
    uint256 public totalETHCollected;
    bool public saleActive;
    uint8 public tokenDecimals;

    // Metrics
    mapping(address => uint256) public tokensPurchased;

    constructor(
        IERC20 _saleToken,
        uint256 _rate,
        uint256 _duration,
        address _owner
    ) {
        require(address(_saleToken) != address(0), "Sale token cannot be the zero address");
        require(_owner != address(0), "Owner cannot be the zero address");
        
        saleToken = _saleToken;
        rate = _rate;
        start = block.timestamp;
        end = start + _duration;
        tokenDecimals = _saleToken.decimals();
        transferOwnership(_owner);
        saleActive = true;
    }

    function buyTokens() external payable nonReentrant {
        require(saleActive, "Sale is not active");
        require(block.timestamp >= start && block.timestamp <= end, "Sale period has ended");
        require(msg.value > 0, "No ETH sent");

        uint256 tokensToTransfer = (msg.value * rate) / (10**18) * (10**tokenDecimals);

        tokensPurchased[msg.sender] += tokensToTransfer;

        totalETHCollected += msg.value;
    }

    function claimTokens() external nonReentrant {
        uint256 amount = tokensPurchased[msg.sender];
        require(amount > 0, "No tokens to claim");

        tokensPurchased[msg.sender] = 0;
        saleToken.safeTransfer(msg.sender, amount);
        
        // Optional: Emit an event for the claim
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // General withdrawal function for ERC20 tokens
    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner(), balance);
    }

     // Function to get sale metrics
     function getSaleMetrics() external view returns (uint256, uint256) {
        return (totalETHCollected, totalTokensSold);
    }
}