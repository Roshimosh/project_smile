Smart contract

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHederaERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract SmilePleaseHedera {
    IHederaERC20 public rewardToken;
    uint256 public rewardAmount;
    address public owner;
    mapping(string => uint8) public smileScores; // photoUrl => smileScore
    mapping(string => bool) public rewarded; // photoUrl => whether reward was given

    event SmileAnalysisSubmitted(string indexed photoUrl, uint8 smileScore);
    event RewardDistributed(string indexed photoUrl, address indexed recipient, uint256 rewardAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(address _rewardTokenAddress, uint256 _rewardAmount) {
        rewardToken = IHederaERC20(_rewardTokenAddress);
        rewardAmount = _rewardAmount;
        owner = msg.sender;
    }

    function submitSmileScore(string memory photoUrl, uint8 smileScore, address recipient) external onlyOwner {
        require(smileScore >= 1 && smileScore <= 5, "Invalid smile score (must be between 1 and 5)");
        require(bytes(photoUrl).length > 0, "Photo URL cannot be empty");
        require(!rewarded[photoUrl], "Reward already distributed for this photo");

        // Record the smile score
        smileScores[photoUrl] = smileScore;

        // Distribute reward if score is 4 or 5
        if (smileScore >= 4) {
            require(rewardToken.transfer(recipient, rewardAmount), "Reward transfer failed");
            rewarded[photoUrl] = true;

            emit RewardDistributed(photoUrl, recipient, rewardAmount);
        }

        emit SmileAnalysisSubmitted(photoUrl, smileScore);
    }

    function getSmileScore(string memory photoUrl) external view returns (uint8) {
        return smileScores[photoUrl];
    }

    function isRewarded(string memory photoUrl) external view returns (bool) {
        return rewarded[photoUrl];
    }

    function setRewardToken(address _newRewardToken) external onlyOwner {
        rewardToken = IHederaERC20(_newRewardToken);
    }

    function setRewardAmount(uint256 _newRewardAmount) external onlyOwner {
        rewardAmount = _newRewardAmount;
    }

    function withdrawFunds(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        recipient.transfer(amount);
    }

    receive() external payable {} // Allow the contract to accept HBAR
}
