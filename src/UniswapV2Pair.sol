// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";

interface IERC20 {
  function balanceOf(address) external returns (uint256);
  function transfer(address to, uint256 amount) external;
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();

contract UniswapV2Pair is ERC20, Math {
  uint256 constant MINIMUM_LIQUIDITY = 1000;

  address public token0;
  address public token1;

  uint112 private reserve0;
  uint112 private reserve1;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1);
  event Sync(uint256 reserve0, uint256 reserve1);
  
  constructor(address token0_, address token1_) ERC20("Uniswap V2", "UNIV2", 18) {
    token0 = token0_;
    token1 = token1_;
  }

  function mint() public {
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));

    uint256 depositAmount0 = balance0 - reserve0;
    uint256 depositAmount1 = balance1 - reserve1;

    // Init liquidity
    uint256 liquidity;
    if (totalSupply == 0) {
      liquidity = Math.sqrt(depositAmount0 * depositAmount1) - MINIMUM_LIQUIDITY;
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = Math.min(
        (totalSupply * depositAmount0) / reserve0, 
        (totalSupply * depositAmount1) / reserve1
      );
    }
    if (liquidity <= 0) revert InsufficientLiquidityMinted();

    _mint(msg.sender, liquidity);
    _update(balance0, balance1);

    emit Mint(msg.sender, depositAmount0, depositAmount1);
  }

  function burn() pulbic {
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));
    uint256 liquidity = balanceOf(msg.sender);

    uint256 removeAmount0 = (balance0 * liquidity) / totalSupply;
    uint256 removeAmount1 = (balance1 * liquidity) / totalSupply;

    if (removeAmount0 <= 0 || removeAmount1 <= 0) revert InsufficientLiquidityBurned();

    _burn(msg.sender, liquidity);
    _safeTransfer(token0, msg.sender, removeAmount0);
    _safeTransfer(token1, msg.sender, removeAmount1);

    balance0 = IERC20(token0).balanceOf(address(this));
    balance1 = IERC20(token1).balanceOf(address(this));
     _update(balance0, balance1);

    emit Burn(msg.sender, removeAmount0, removeAmount1);
  }

  function sync() public {
    _update(
      IERC20(token0).balanceOf(address(this)),
      IERC20(token1).balanceOf(address(this))
    );
  }

  function getReserves() public view returns (uint112, uint112, uint32) {
    return (reserve0, reserve1, 0);
  }

  function _update(uint256 balance0, uint256 balance1) private {
    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);

    emit Sync(reserve0, reserve1);
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSignature("transfer(address,uint256)", to, value)
    );
    if (!success || (data.length != 0 && !abi.decode(data, (bool))))
      revert TransferFailed();
  }
}


