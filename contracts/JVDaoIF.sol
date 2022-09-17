// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC20.sol";

contract JVDAOFactory {
    function create(
        // DAO0
        address dao0,
        uint256 numTokens0,
        address tokenAdd0,
        // DAO1
        address dao1,
        uint256 numTokens1,
        address tokenAdd1,
        // NEW OWNER
        address newOwner,
        uint256 split,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenSupply
    ) public returns (JVDaoIF) {
        JVDaoIF jvd = new JVDaoIF(
            dao0,
            numTokens0,
            tokenAdd0,
            dao1,
            numTokens1,
            tokenAdd1,
            newOwner,
            split,
            tokenName,
            tokenSymbol,
            tokenSupply
        );

       return jvd;
    }
}

interface UniswapV3Factory {
    function deploy(
        address tokenA,
        address tokenB,
        uint24 fee
  ) external returns (address pool);
}
interface Pool {
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes memory data
  ) external returns (uint256 amount0, uint256 amount1);
}

interface SetTokenCreator {
    function create(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        address _manager,
        string memory _name,
        string memory _symbol
  ) external returns (address);
}

contract JVDaoIF {
    address public dao0;
    uint256 public numTokens0;
    address public tokenAdd0;

    address public dao1;
    uint256 public numTokens1;
    address public tokenAdd1;

    address public newOwner;
    uint256 public split;
    string public tokenName;
    string public tokenSymbol;
    uint256 public tokenSupply;

    constructor(
        // DAO0
        address _dao0,
        uint256 _nTokens0,
        address _tokenAdd0,
        // DAO1
        address _dao1,
        uint256 _nTokens1,
        address _tokenAdd1,
        // NEW OWNER
        address _newOwner,
        uint256 _split,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenSupply
    ) {
        dao0 = _dao0;
        numTokens0 = _nTokens0;
        dao1 = _dao1;
        newOwner = _newOwner;
        numTokens1 = _nTokens1;
        tokenAdd1 = _tokenAdd1;
        tokenAdd0 = _tokenAdd0;
        split = _split;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenSupply = _tokenSupply;
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules) 
    public returns(address){
        // SetTokenCreator - 0xeF72D3278dC3Eba6Dc2614965308d1435FFd748a
        address newToken = SetTokenCreator(0xeF72D3278dC3Eba6Dc2614965308d1435FFd748a).create(
            _components, // components
            _units, //[2, 1], // units
            _modules, // [0xeF72D3278dC3Eba6Dc2614965308d1435FFd748a], // modules
            address(this), // manager
            _name,
            _symbol
        );
        
        //ERC20 newToken = new ERC20(_name, _symbol, _supply);
        return address(newToken);
    }
    
    address[] hh;
    int256[] vv;
    address[] dd;

    function mint() public {
        // burn the tokens
        //ERC20(tokenAdd0).transferFrom(dao0, address(0), nTokens0);
        //ERC20(tokenAdd1).transferFrom(dao1, address(0), nTokens1);

        hh.push(tokenAdd0);
        hh.push(tokenAdd1);
        
        vv.push(1);
        vv.push(2);
       
        dd.push(address(this));

        // create new token
        address newTokenAddr = createToken(tokenName, tokenSymbol, hh, vv, dd);

        // do the split
        ERC20(newTokenAddr).transfer(dao0, tokenSupply * split);
        ERC20(newTokenAddr).transfer(dao1, tokenSupply * (1-split));

        // create liquidity pool
        address poolAddr0 =  UniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984).deploy(newTokenAddr, tokenAdd0, 3);
        address poolAddr1 = UniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984).deploy(newTokenAddr, tokenAdd1, 3);

        // provide liquidity
        Pool(poolAddr0).mint(
            dao0,
            -887272, // tickLower
            887272, // tickUpper
            (uint128) (tokenSupply * split), // amount
            "" // data
        );

        Pool(poolAddr1).mint(
            dao0,
            -887272, // tickLower
            887272, // tickUpper
            (uint128) (tokenSupply * (1-split)), // amount
            "" // data
        );
    }
}
