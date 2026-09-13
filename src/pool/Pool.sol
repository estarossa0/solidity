// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IPool} from "./interfaces/IPool.sol";

/**
 * @title Pool
 * @author Estarossa
 */
contract Pool is IPool, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*------------------------------------------------------------------------*/
    /* Immutable state */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Token 0
     */
    IERC20 public immutable override token0;

    /**
     * @notice Token 1
     */
    IERC20 public immutable override token1;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    /*------------------------------------------------------------------------*/
    /* State variables */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Token 0 reserve
     */
    uint256 internal reserve0;

    /**
     * @notice Token 1 reserve
     */
    uint256 internal reserve1;

    /**
     * @notice Total supply of liquidity shares
     */
    uint256 public override totalSupply;

    /**
     * @notice Liquidity share balance by account
     */
    mapping(address => uint256) public override balanceOf;

    /*------------------------------------------------------------------------*/
    /* Constructor */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Pool constructor
     * @param _token0 Token 0
     * @param _token1 Token 1
     */
    constructor(address _token0, address _token1) {
        if (_token0 == _token1) revert InvalidAddress();
        if (_token0 == address(0) || _token1 == address(0)) revert InvalidAddress();

        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /*------------------------------------------------------------------------*/
    /* Internal helpers */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Mint liquidity shares
     * @param _to Recipient
     * @param _amount Share amount
     */
    function _mint(address _to, uint256 _amount) private {
        /* Credit shares to the recipient */
        balanceOf[_to] += _amount;

        /* Increase total supply */
        totalSupply += _amount;
    }

    /**
     * @notice Burn liquidity shares
     * @param _from Holder
     * @param _amount Share amount
     */
    function _burn(address _from, uint256 _amount) private {
        /* Debit shares from the holder */
        balanceOf[_from] -= _amount;

        /* Decrease total supply */
        totalSupply -= _amount;
    }

    /**
     * @notice Update reserves
     * @param _reserve0 Token 0 reserve
     * @param _reserve1 Token 1 reserve
     */
    function _update(uint256 _reserve0, uint256 _reserve1) private {
        /* Store token 0 reserve */
        reserve0 = _reserve0;

        /* Store token 1 reserve */
        reserve1 = _reserve1;
    }

    /*------------------------------------------------------------------------*/
    /* Public API */
    /*------------------------------------------------------------------------*/

    /**
     * @inheritdoc IPool
     */
    function swap(address _tokenIn, uint256 _amountIn, uint256 _minAmountOut, uint256 _deadline)
        external
        override
        nonReentrant
        returns (uint256 amountOut)
    {
        /* Validate the deadline has not passed */
        if (block.timestamp > _deadline) revert Expired();

        /* Validate input token is one of the pool tokens */
        require(_tokenIn == address(token0) || _tokenIn == address(token1), "invalid token");

        /* Validate input amount is non-zero */
        require(_amountIn > 0, "amount in = 0");

        /* Determine swap direction */
        bool isToken0 = _tokenIn == address(token0);

        /* Resolve input and output tokens and reserves */
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) =
            isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);

        /* Validate the pool is initialized on both sides */
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        /* Read input token balance before the transfer */
        uint256 initialBalIn = tokenIn.balanceOf(address(this));

        /* Transfer input token in from sender to this contract */
        tokenIn.safeTransferFrom(msg.sender, address(this), _amountIn);

        /* Get the real input amount from the transfer result */
        uint256 amountInReceived = tokenIn.balanceOf(address(this)) - initialBalIn;

        /* Apply 0.3% swap fee to the received amount */
        uint256 amountInWithFee = (amountInReceived * 997) / 1000;

        /* Compute output amount from the constant product invariant */
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        /* Validate output amount is non-zero */
        if (amountOut == 0) revert ZeroOutputAmount();

        /* Validate output amount meets the caller's minimum */
        if (amountOut < _minAmountOut) revert InsufficientOutputAmount();

        /* Transfer output token from this contract to the sender */
        tokenOut.safeTransfer(msg.sender, amountOut);

        /* Update reserves to the current token balances */
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /**
     * @inheritdoc IPool
     */
    function addLiquidity(uint256 _amount0In, uint256 _amount1In, uint256 _minShares, uint256 _deadline)
        external
        override
        nonReentrant
        returns (uint256 shares)
    {
        /* Validate the deadline has not passed */
        if (block.timestamp > _deadline) revert Expired();

        /* Read current token balances */
        uint256 initialBal0 = token0.balanceOf(address(this));
        uint256 initialBal1 = token1.balanceOf(address(this));

        /* Transfer token 0 and 1 in from sender to this contract */
        token0.safeTransferFrom(msg.sender, address(this), _amount0In);
        token1.safeTransferFrom(msg.sender, address(this), _amount1In);

        /* Read Final token balances */
        uint256 finalBal0 = token0.balanceOf(address(this));
        uint256 finalBal1 = token1.balanceOf(address(this));

        /* Get real amounts from transfer results */
        uint256 _amount0 = finalBal0 - initialBal0;
        uint256 _amount1 = finalBal1 - initialBal1;

        /* Compute shares from the initial deposit or pro-rata against reserves */
        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
            if (shares < MINIMUM_LIQUIDITY + 1) revert BelowMinLiquidity();
            _mint(address(0), MINIMUM_LIQUIDITY);
            shares -= MINIMUM_LIQUIDITY;
        } else {
            shares = _min((_amount0 * totalSupply) / initialBal0, (_amount1 * totalSupply) / initialBal1);
        }

        /* Validate shares are non-zero */
        require(shares > 0, "shares = 0");

        /* Validate minted shares meet the caller's minimum */
        if (shares < _minShares) revert InsufficientShares();

        /* Mint shares to the sender */
        _mint(msg.sender, shares);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /**
     * @inheritdoc IPool
     */
    function removeLiquidity(uint256 _shares)
        external
        override
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        /* Read current token balances */
        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        /* Compute pro-rata token amounts for the shares */
        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;

        /* Validate both amounts are non-zero */
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        /* Burn the sender's shares */
        _burn(msg.sender, _shares);

        /* Update reserves net of the withdrawn amounts */
        _update(bal0 - amount0, bal1 - amount1);

        /* Transfer token 0 from this contract to the sender */
        token0.safeTransfer(msg.sender, amount0);

        /* Transfer token 1 from this contract to the sender */
        token1.safeTransfer(msg.sender, amount1);
    }

    /*------------------------------------------------------------------------*/
    /* Math helpers */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Square root (Babylonian method)
     * @param y Value
     * @return z Square root
     */
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        /* Iterate until the estimate stops decreasing */
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            /* Square root of 1, 2, and 3 is 1 */
            z = 1;
        }
    }

    /**
     * @notice Minimum of two values
     * @param x First value
     * @param y Second value
     * @return Minimum value
     */
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        /* Return the smaller of the two values */
        return x <= y ? x : y;
    }
}
