//SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Stablecoin} from "./Stablecoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from  "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";


contract StablecoinSkeleton is ReentrancyGuard {

    error StablecoinSkeleton__NeedsMoreThanZero();
    error StablecoinSkeleton__TokenAddressandPriceFeedAddressesMustHaveSameLength();
    error StablecoinSkeleton__NotAllowedToken();
    error StablecoinSkeleton__TransferFailed();
    error StablecoinSkeleton__BreaksHealthFactor(uint256 healthFactor);
    error StablecoinSkeleton__MintingFailed();
    error StablecoinSkeleton__HealthFactorIsfine();

    uint256 private constant LIQUIDITATION_THRESHOLD = 50;




    mapping (address token => address PriceFeed) private s_PriceFeed;
    mapping (address user => mapping(address token => uint256 amount)) private s_collateralDeposit;
    mapping(address user => uint256 amountSBTminted) private s_SBTminted;
    address[] private s_collateralTokens;

    Stablecoin private immutable i_stablecoin;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 indexed amount);

    modifier CollateralMoreThanZero(uint256 _amount){
        if(_amount == 0){
            revert StablecoinSkeleton__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if(s_PriceFeed[token] == address(0)){
            revert StablecoinSkeleton__NotAllowedToken();
        } 
        _;
    }

    constructor(address [] memory tokenAddresses, address [] memory priceFeedAddress, address StablecoinAddress) {
        if(tokenAddresses.length != priceFeedAddress.length){
            revert StablecoinSkeleton__TokenAddressandPriceFeedAddressesMustHaveSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++){
            s_PriceFeed[tokenAddresses[i]] = priceFeedAddress[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_stablecoin = Stablecoin(StablecoinAddress);
    }

    function DepositCollateralandmintSBT(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountSBTtomint) external {
        mintSBT(amountSBTtomint);
    }

    function DepositCollateral(address _tokenCollateralAddress, uint256 _amountOfCollateral)
    public
    CollateralMoreThanZero(_amountOfCollateral)
    isAllowedToken(_tokenCollateralAddress)
    nonReentrant
{
    s_collateralDeposit[msg.sender][_tokenCollateralAddress] += _amountOfCollateral;
    emit CollateralDeposited(msg.sender, _tokenCollateralAddress, _amountOfCollateral);
    bool success = IERC20(_tokenCollateralAddress).transferFrom(
        msg.sender,
        address(this),
        _amountOfCollateral
    );
    if (!success) {
        revert StablecoinSkeleton__TransferFailed();
    }
}
        function redeemCollateralForSBT(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountSBTtoburn) external {
            burnSBT(amountSBTtoburn);
            redeemCollateral(tokenCollateralAddress, amountCollateral);
        }
        function redeemCollateral(address tokencollateralAddress, uint256 amountofCollateral) public CollateralMoreThanZero(amountofCollateral) nonReentrant {
            s_collateralDeposit[msg.sender][tokencollateralAddress] -= amountofCollateral;
            emit CollateralRedeemed(msg.sender, tokencollateralAddress, amountofCollateral);
            bool success = IERC20(tokencollateralAddress).transfer(msg.sender, amountofCollateral);
            if(!success){
                revert StablecoinSkeleton__TransferFailed();
            }
        }

        function mintSBT(uint256 amountSBTtobeMinted) public CollateralMoreThanZero(amountSBTtobeMinted) nonReentrant {
            s_SBTminted[msg.sender] += amountSBTtobeMinted;
            revertifHealthFactordoesNotWork(msg.sender);
            bool minted = i_stablecoin.mint(msg.sender, amountSBTtobeMinted);
            if(!minted){
                revert StablecoinSkeleton__MintingFailed();
            }
        }

        function burnSBT(uint256 _amount) public CollateralMoreThanZero(_amount) {
            s_SBTminted[msg.sender] -= _amount;
            bool success = i_stablecoin.transferFrom(msg.sender, address(this), _amount);
            if (!success){
                revert StablecoinSkeleton__TransferFailed();
            }
            i_stablecoin.burn(_amount);
            revertifHealthFactordoesNotWork(msg.sender);
        }

        function liquidate(address collateral, address user, uint256 debtToCover) external CollateralMoreThanZero(debtToCover) {
            uint256 startingUserHealthFactor = Healthfactor(user);
            if(startingUserHealthFactor >= 1e18) {
                revert StablecoinSkeleton__HealthFactorIsfine();
            }
            uint256 tokenAmountFromDebtCovered = getTokenamountfromUSD(collateral, debtToCover);
            uint256 bonusCollateral = (tokenAmountFromDebtCovered * 10) / 100;
            uint256 totalCollateraltoRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        }

        function getAccountInformation(address user) private view returns(uint256 totalSBTMinted, uint256 collateralValueInUSD){
            totalSBTMinted = s_SBTminted[user];
            collateralValueInUSD = getAccountCollateralValue(user);
        }

        function Healthfactor(address user) private view returns(uint256){
            (uint256 totalSBTminted, uint256 collateralvalueinUSD) = getAccountInformation(user);
            uint256 CollateralAdjustedForThreshold = (collateralvalueinUSD * LIQUIDITATION_THRESHOLD) / 100;
            return (CollateralAdjustedForThreshold * 1e10) / totalSBTminted;

            
            
        }

        function revertifHealthFactordoesNotWork(address user) internal view {
            uint256 userHealthFactor = Healthfactor(user);
            if(userHealthFactor < 1) {
                revert StablecoinSkeleton__BreaksHealthFactor(userHealthFactor);
            }
        }

        function getTokenamountfromUSD(address token, uint256 USDamountinWei) public view returns(uint256){
            AggregatorV3Interface priceFeed = AggregatorV3Interface(s_PriceFeed[token]);
            (, int256 answer,,,) = priceFeed.latestRoundData();
            return (USDamountinWei * 1e18) / (uint256(answer) * 1e10);  
        }

        function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueinUSD){
            for(uint256 i = 0; i <s_collateralTokens.length; i++){
                address token = s_collateralTokens[i];
                uint256 amount = s_collateralDeposit[user][token];
                totalCollateralValueinUSD += getUSDValue(token, amount);
            }
            return totalCollateralValueinUSD;

        }

        function getUSDValue(address token, uint256 amount) public view returns(uint256){
            AggregatorV3Interface priceFeed = AggregatorV3Interface(s_PriceFeed[token]);
            (, int256 answer,,,) = priceFeed.latestRoundData();
            return((uint256(answer) * 1e10) * amount) / 1e18;

        }

}