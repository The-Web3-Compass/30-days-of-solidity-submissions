//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// An Automated Market Maker (AMM) is a decentralized trading mechanism that uses mathematical formulas and liquidity pools instead of traditional order books to automatically determine asset prices and execute trades on blockchain platforms.
// AMM is a two-sided market. It needs both Token A and Token B to form a trading pair.
// Add liquidity: Deposit A+B → enable swaps → earn swap fees(LP token)
// LP tokens are exactly the "proof of ownership" for the Token A and Token B that a user deposits into the pool. They can be minted or burned.

// Users have two rules:
// Role,                  Action,                                  Function
// Liquidity Provider (LP),"Deposits both A and B, gets LP tokens","addLiquidity(A, B)"
// Trader,                "Deposits only one, gets the other",      swapAforB() / swapBforA()

//The AMM uses a simple formula:
//  x × y = k
//  Let’s break that down.
//  - `x` = amount of Token A in the pool
//  - `y` = amount of Token B in the pool
//  - `k` = some constant number (it never changes)
//  So the **product of the two token reserves must always stay the same**.
// That's how prices adjust

// What AMM can do :
// 1. **Swap** tokens
//     - Instantly trade Token A for Token B (or the other way around)
//     - No need to wait for a match
//     - Just send the token, get the other back
// 2. **Add liquidity**
//     - Deposit equal value of Token A and B
//     - You get **LP tokens** (like a receipt)
//     - You earn a cut of trading fees while your tokens are in the pool
// 3. **Remove liquidity**
//     - Return your LP tokens
//     - Get your share of both tokens back

// ERC20 is a standard for creating tokens on Ethereum.
// It defines how tokens behave:
// 1. How to send and receive tokens;("transfer")
// 2. How to give someone else permission to use them;("approve"+"transferFrom")
// 3. How to check balances;("balanceOf")
// 4. How to create or destroy tokens;("mint" and "burn")
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutomatedMarketMaker is ERC20{
    // These two varaibles hold the addressed of the ERC-20 tokens this AMM will manage.
    // They are typed as "IERC20" which is just an interface.
    IERC20 public tokenA;
    IERC20 public tokenB;

    // These two numbers track how much of each token is currently locked inside the AMM contract.
    uint256 public reserveA;
    uint256 public reserveB;

    address public owner;

    // This is triggered whenever someone add tokens to the pool.
    event LiquidityAdded(address indexed provider, uint256 amountA,uint256 amountB,uint256 liquidity);
    // This is triggered when someone removes liquidity from the pool.
    event LiquidityRemoved(address indexed provider,uint256 amountA,uint256 amountB,uint256 liquidity);
    // This is triggered whenever somenone swaps one token for the other.
    event TokensSwapped(address indexed trader,address tokenIn,uint256 amountIn,address tokenOut,uint256 amountOut);

    // _name: the name for the LP token
    // _symbol: the symbol for the LP token
    constructor(address _tokenA,address _tokenB,string memory _name,string memory _symbol) ERC20(_name,_symbol){
        tokenA=IERC20(_tokenA);
        tokenB=IERC20(_tokenB);
        owner=msg.sender;
    }
    // This function lets a user add liquidity to the pool by depositing equal value amounts of TokenA and TokenB
    // This function is for LP provider
    function addLiquidity(uint256 amountA,uint256 amountB) external{
        require(amountA>0&&amountB>0,"Amounts must be >0");

        tokenA.transferFrom(msg.sender,address(this),amountA);
        tokenB.transferFrom(msg.sender,address(this),amountB);

        uint256 liquidity;
        // "totalSupply()" is the function in ERC20.sol.
        if(totalSupply()==0){
            liquidity=sqrt(amountA*amountB);
        }
        else{
            liquidity=min(amountA*totalSupply()/reserveA,amountB*totalSupply()/reserveB);
        }

        _mint(msg.sender,liquidity);
        reserveA+=amountA;
        reserveB+=amountB;
        emit LiquidityAdded(msg.sender,amountA,amountB,liquidity);

    }

    function removeLiquidity(uint256 liquidityToRemove) external returns(uint256 amountAOut,uint256 amountBOut){
        require(liquidityToRemove>0,"Liquidity to remove must be >0");
        require(balanceOf(msg.sender)>=liquidityToRemove,"Insufficient liquidity tokens");
        
        uint256 totalLiquidity=totalSupply();
        require(totalLiquidity>0,"No liquidity in the pool");

        amountAOut=liquidityToRemove*reserveA/totalLiquidity;
        amountBOut=liquidityToRemove*reserveB/totalLiquidity;

        require(amountAOut>0&&amountBOut>0,"Insufficient reserves for requested liquidity");

        reserveA-=amountAOut;
        reserveB-=amountBOut;

        _burn(msg.sender,liquidityToRemove);

        tokenA.transfer(msg.sender,amountAOut);
        tokenB.transfer(msg.sender,amountBOut);

        emit LiquidityRemoved(msg.sender,amountAOut,amountBOut,liquidityToRemove);
        return(amountAOut,amountBOut);
    }

    function swapAforB(uint256 amountAIn,uint256 minBOut) external{
        require(amountAIn>0,"Amount must be >0");
        require(reserveA>0&&reserveB>0,"Insufficient reserves");

        // Substract a 0.3% fee for a reward of liquidity providers.
        uint256 amountAInWithFee=amountAIn*997/1000;
        // Calculate Token B the user should get for the amount of Token A they're putting in.
        // In "x*y=k", keep "k" constant.
        uint256 amountBOut=reserveB*amountAInWithFee/(reserveA+amountAInWithFee);

        require(amountBOut>=minBOut,"Slippage too high");

        tokenA.transferFrom(msg.sender,address(this),amountAIn);
        tokenB.transfer(msg.sender,amountBOut);

        reserveA+=amountAInWithFee;
        reserveB-=amountBOut;

        emit TokensSwapped(msg.sender,address(tokenA),amountAIn,address(tokenB),amountBOut);

    }

    function swapBforA(uint256 amountBIn,uint256 minAOut) external{
        require(amountBIn>0,"Amount must be >0");
        require(reserveA>0&&reserveB>0,"Insufficient reserves");

        uint256 amountBInWithFee=amountBIn*997/1000;
        uint256 amountAOut=reserveA*amountBInWithFee/(reserveB+amountBInWithFee);

        require(amountAOut>=minAOut,"Slippage too high");

        tokenB.transferFrom(msg.sender,address(this),amountBIn);
        tokenA.transfer(msg.sender,amountAOut);

        reserveB+=amountBInWithFee;
        reserveA==amountAOut;

        emit TokensSwapped(msg.sender,address(tokenB),amountBIn,address(tokenA),amountAOut);


    }

    function getReserves() external view returns(uint256,uint256){
        return (reserveA,reserveB);

    }

    function min(uint256 a ,uint256 b) internal pure returns(uint256){
        return a<b?a:b;

    }

    // This is a classic Babylonian algorithm for calculating the square root of a number is Solidity.
    function sqrt(uint256 y) internal pure returns(uint256 z){
        if(y>3){
            z=y;
            uint256 x=y/2+1;
            while(x<z){
                z=x;
                x=(y/x+x)/2;
            }
        }
        else if (y!=0){
                z=1;
            }

    }
}