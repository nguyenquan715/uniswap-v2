// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import {UniswapV2Pair} from "./UniswapV2Pair.sol";

library UniswapV2Library {
  error InsufficientAmount();
  error InsufficientLiquidity();

  function getReserves(
    address factoryAddress,
    address tokenA,
    address tokenB
  ) public returns (uint256 reserveA, uint256 reserveB) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    address pairAddress = pairFor(factoryAddress, token0, token1);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
    (reserveA, reserveB) = token0 == tokenA ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function quote(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) public pure returns (uint256 amountOut) {
    if (amountIn == 0) revert InsufficientAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

    return (amountIn * reserveOut) / reserveIn;
  }

  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address, address) {
    return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  function pairFor(
    address factoryAddress,
    address tokenA,
    address tokenB
  ) internal pure returns (address pairAddress) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pairAddress = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factoryAddress,
              keccak256(abi.encodePacked(token0, token1)),
              keccak256(type(UniswapV2Pair).creationCode)
            )
          )
        )
      )
    );
  }
}
