// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Pool Interface
 * @author Estarossa
 */
interface IPool {
    /*------------------------------------------------------------------------*/
    /* Errors */
    /*------------------------------------------------------------------------*/

    error InvalidAddress();
    error BelowMinLiquidity();

    /**
     * @notice Deadline has passed
     */
    error Expired();

    /**
     * @notice Minted shares below the caller's minimum
     */
    error InsufficientShares();

    /**
     * @notice Pool has no liquidity
     */
    error InsufficientLiquidity();

    /**
     * @notice Output amount is zero
     */
    error ZeroOutputAmount();

    /**
     * @notice Output amount below the caller's minimum
     */
    error InsufficientOutputAmount();

    /**
     * @notice Caller holds fewer shares than requested
     */
    error InsufficientBalance();

    /**
     * @notice Token 0 amount below the caller's minimum
     */
    error InsufficientAmount0();

    /**
     * @notice Token 1 amount below the caller's minimum
     */
    error InsufficientAmount1();

    /*------------------------------------------------------------------------*/
    /* Getters */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Get token 0
     * @return Token 0
     */
    function token0() external view returns (IERC20);

    /**
     * @notice Get token 1
     * @return Token 1
     */
    function token1() external view returns (IERC20);

    /**
     * @notice Get total supply of liquidity shares
     * @return Total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Get liquidity share balance of an account
     * @param account Account
     * @return Share balance
     */
    function balanceOf(address account) external view returns (uint256);

    /*------------------------------------------------------------------------*/
    /* Public API */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Swap an input token for the other pool token
     * @param _tokenIn Input token
     * @param _amountIn Input amount
     * @param _minAmountOut Minimum acceptable output amount
     * @param _deadline Expiry timestamp
     * @return amountOut Output amount
     */
    function swap(address _tokenIn, uint256 _amountIn, uint256 _minAmountOut, uint256 _deadline)
        external
        returns (uint256 amountOut);

    /**
     * @notice Add liquidity
     * @param _amount0 Token 0 amount
     * @param _amount1 Token 1 amount
     * @param _minShares Minimum acceptable shares
     * @param _deadline Expiry timestamp
     * @return shares Shares minted
     */
    function addLiquidity(uint256 _amount0, uint256 _amount1, uint256 _minShares, uint256 _deadline)
        external
        returns (uint256 shares);

    /**
     * @notice Remove liquidity
     * @param _shares Shares to burn
     * @param _minAmount0 Minimum acceptable token 0 amount
     * @param _minAmount1 Minimum acceptable token 1 amount
     * @param _deadline Expiry timestamp
     * @return amount0 Token 0 amount
     * @return amount1 Token 1 amount
     */
    function removeLiquidity(uint256 _shares, uint256 _minAmount0, uint256 _minAmount1, uint256 _deadline)
        external
        returns (uint256 amount0, uint256 amount1);
}
