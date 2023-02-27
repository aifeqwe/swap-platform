pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

abstract contract  Context {

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

 abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }


    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
  
    function totalSupply() external view returns (uint256);



    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);

 
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

 }



contract swapPlatform is Ownable {

    event _createPair(address indexed _from, address token1Address,address token2Address); //added
    event addLiquidity(address indexed _from, address token1Address,address token2Address, uint token1Value, uint token2Value);//added
    event removeLiquidity(address indexed _from, address token1Address,address token2Address, uint token1Value, uint token2Value);
    event addToken(address indexed _from,address tokenContractAddress, string tokenName); //added
    event _addStableCoin(address indexed _from, address tokenContractAddress,string tokenName);//added
    event _removeStableCoin(address indexed _from, address tokenContractAddress,string tokenName);//added
    event _swap(address indexed _from, address fromTokenContractAddress,address toTokenContractAddress, uint TokenSoldValue, uint valueReceived);

        function addNewToken(address contractAddress) public returns(string memory) {
            if(tokensInfo[contractAddress].isSubmitedBefore == false){
                uint8 errorNumber;
                tokensInfo[contractAddress].tokenContractAddress = IERC20(contractAddress);
                tokensInfo[contractAddress].tokenName = tokensInfo[contractAddress].tokenContractAddress.name();
                if( stringLength(tokensInfo[contractAddress].tokenName)==0){errorNumber++;}
                tokensInfo[contractAddress].tokenSymbol = tokensInfo[contractAddress].tokenContractAddress.symbol();
                if( stringLength(tokensInfo[contractAddress].tokenSymbol)==0){errorNumber++;}
                tokensInfo[contractAddress].decimals = tokensInfo[contractAddress].tokenContractAddress.decimals();
                if( tokensInfo[contractAddress].decimals==0){errorNumber++;}
                if(errorNumber >2){ return "this is not a Standard token contract Address" ;}else{
                tokensInfo[contractAddress].isSubmitedBefore = true;
                tokensInfo[contractAddress].tokensBalance = 0;
                emit addToken(msg.sender,contractAddress,tokensInfo[contractAddress].tokenName);
                return "This token has been added";
                }
            }else{
                return "This token has already been added ";
            }
        }
        function tokenDecimalsView(address tokenContractAddress )public view returns(uint ){
            return
            tokensInfo[tokenContractAddress].decimals;
        }
        function tokenSymbolView( address tokenContractAddress) public view returns(string memory){
            return
            tokensInfo[tokenContractAddress].tokenSymbol;
        }
        function tokenNameView(address tokenContractAddress ) public view returns(string memory){
            return
            tokensInfo[tokenContractAddress].tokenName;
        }
        function tokenBalanceview(address tokenContractAddress) public view returns(uint256){
            return tokensInfo[tokenContractAddress].tokensBalance;
        }
        function tokenLiquidityPoolsview(address tokenContractAddress)public view returns(bytes[]memory){
            return tokensInfo[tokenContractAddress].poolsForThisToken;
        }
        function tokenPairsCount(address tokenContractAddress) view public returns(uint256){
            return tokensInfo[tokenContractAddress].poolsForThisToken.length;
        }
        //following function recive a token contract address and pair number and returns specific pair name
        function tokenPairsName(address tokenContractAddress,uint256 i) view public returns (string memory ) {
                return _liquidityPools[tokenLiquidityPoolsview(tokenContractAddress)[i]].pairName;
        }
        //following function recive a token contract address and pair number and returns count of specific token in contract
        function tokenCountInPair(address tokenContractAddress,uint256 i) view public returns (uint256 ) {
            if(ConvertIDToOneOfPairContractAddress(tokenLiquidityPoolsview(tokenContractAddress)[i],1)== tokenContractAddress){
                return _liquidityPools[tokenLiquidityPoolsview(tokenContractAddress)[i]].token1Amount;
            }else{
                return _liquidityPools[tokenLiquidityPoolsview(tokenContractAddress)[i]].token2Amount;
            }   
        }
       
        function stringTokenDecimal(address tokenContractAddress)public view returns(string memory){
            return string.concat("\ndecimals:",Strings.toString(tokenDecimalsView(tokenContractAddress)));
        }
        function stringTokenBalance(address tokenContractAddress)public view returns(string memory){
            return
            string.concat(" \ntotal liquidity:",Strings.toString(tokenBalanceview(tokenContractAddress)),tokenSymbolView(tokenContractAddress));

        }
        function stringTokenPairName(address tokenContractAddress,uint i ) public view returns(string memory){
            return string.concat("pool Name:",tokenPairsName(tokenContractAddress,i));
        }


        function _viewTokenInfo(address contractAddress)public view returns(string [] memory,string [] memory) {
            require(tokensInfo[contractAddress].isSubmitedBefore == true, "token not found");

            for(uint i =0; i< tokenPairsCount(contractAddress)  ; i++ ){
            }

        }
                function addStableCoin(address contractAddress) public onlyOwner returns(bool){
            IsStableCoin[contractAddress]=true;
            emit _addStableCoin(msg.sender,contractAddress, IERC20(contractAddress).name());
            return true;
        }
        function removeStableCoin(address contractAddress) public onlyOwner returns(bool){
            IsStableCoin[contractAddress]=false;
            emit _removeStableCoin(msg.sender,contractAddress, IERC20(contractAddress).name());
            return true;
        }
        function findUserPoolIdByID(address userWalletAddress,uint i) public view returns (bytes memory){
            return _userLiquidity[userWalletAddress].userPools[i];
        }
        function findUserPoolNameByID(address userWalletAddress,uint i) view public returns (string memory){
            return _liquidityPools[findUserPoolIdByID(userWalletAddress,i)].pairName;
        }
        function findUserToken1InPool(address userWalletAddress ,uint i )view public returns(uint256){
            return _userLiquidity[userWalletAddress].token1Inpool[findUserPoolIdByID(userWalletAddress,i)];
        }    
        function findUserToken2InPool(address userWalletAddress ,uint i) view public returns(uint256){
            return _userLiquidity[userWalletAddress].token2Inpool[findUserPoolIdByID(userWalletAddress,i)];
        }
        function findUserCountPool(address userWalletAddress ) public view returns(uint256){
            return _userLiquidity[userWalletAddress].userPools.length;
        }

        function _userLiquidityView(address userWalletAddress) public view returns( string[] memory,string memory){
            uint256 allUserPoolCount =_userLiquidity[userWalletAddress].userPools.length;
            string memory poolName;
            uint256 token1InPool;
            uint256 token2InPool;
            address token1ContractAddress;
            address token2ContractAddress;
            string memory token1Symbol;
            string memory token2Symbol;
            bytes memory poolId;
            string[] memory allInfo;
            for(uint i=0; i< (allUserPoolCount * 3);i+=3){
                poolId =_userLiquidity[userWalletAddress].userPools[i/3];
                token1InPool = _userLiquidity[userWalletAddress].token1Inpool[poolId];
                token2InPool = _userLiquidity[userWalletAddress].token2Inpool[poolId];
                poolName = _liquidityPools[poolId].pairName;
                (token1ContractAddress,token2ContractAddress) = ConvertIDToContractAddress(poolId);
                token1Symbol = tokensInfo[token1ContractAddress].tokenSymbol;
                token2Symbol = tokensInfo[token2ContractAddress].tokenSymbol;
                 allInfo[i] = string.concat(Strings.toString(i/3+1), ": " , poolName , ": \n ");
                 allInfo[i+1] = string.concat("pair: " ,":",Strings.toString(token1InPool),token1Symbol);
                 allInfo[i+2] = string.concat("\n",": ",Strings.toString(token2InPool),token2Symbol,"\n" );
            }
            return (allInfo , "Note:Decimals are not displayed here");
        }


        // this functions recive pool Id and send back contract address
        function ConvertIDToOneOfPairContractAddress(bytes memory poolId,uint contractToReturn) pure private returns (address){
            address  address1;
            address  address2;
            (address1,address2)=abi.decode(poolId,(address,address) );
            if(contractToReturn==1){return address1;}else{ return address2;}

        }

        function ConvertIDToContractAddress(bytes memory poolId)pure private returns(address,address){
            return abi.decode(poolId,(address,address) );
        }

        function convertIDToOppositeContractAdress(bytes memory poolId,address tokenContractAddress) pure private returns(address){
            (address token1, address token2)=abi.decode(poolId,(address,address) );
            if(tokenContractAddress== token1){
                return (token2);
            }else{return (token1);}
        }

        //this function calculate length of strings
            function stringLength(string memory s) private pure returns ( uint256) {
        return bytes(s).length;
        }

        function createPool(address address1,address address2) private returns(bytes memory) {
            bytes memory poolId;
            if(IsStableCoin[address1] == true){
                poolId = abi.encode(address2,address1);
            }else{
                poolId = abi.encode(address1,address2);
            }
            _liquidityPools[poolId].isPoolCreated = true;
            if(tokensInfo[address1].isSubmitedBefore == false){
                addNewToken(address1);
            }
            if(tokensInfo[address2].isSubmitedBefore== false){
                addNewToken(address2);
            }
            tokensInfo[address1].poolsForThisToken.push(poolId);
            tokensInfo[address2].poolsForThisToken.push(poolId);
            _liquidityPools[poolId].pairName = string.concat(tokensInfo[address1].tokenSymbol,"/", tokensInfo[address2].tokenSymbol);
            emit _createPair(msg.sender, ConvertIDToOneOfPairContractAddress(poolId,1),ConvertIDToOneOfPairContractAddress(poolId,2));
            return poolId;
            }

            function calculateTokenRateForAddLiqudity
            (uint256 token1Amount, uint256 token2Amount,bytes memory poolId) private view returns(uint256 ,uint256){
                    uint256 token1TenThousand;
                   uint256 token2TenThousand;
                    uint256 calculatedToken1Amount;
                   uint256 calculatedToken2Amount;

                   if( (stringLength(Strings.toString(token1Amount)) +stringLength(Strings.toString(token2Amount) )) < 78 ){
                       if(  ((token1Amount * _liquidityPools[poolId].token2Amount)/ _liquidityPools[poolId].token1Amount) > token2Amount ){
                           calculatedToken1Amount =
                           (token2Amount * _liquidityPools[poolId].token1Amount) / _liquidityPools[poolId].token2Amount;
                           calculatedToken2Amount = token2Amount;
                       } else{
                           calculatedToken2Amount=
                           ((token1Amount * _liquidityPools[poolId].token2Amount)/ _liquidityPools[poolId].token1Amount);
                           calculatedToken1Amount = token1Amount;
                       }
                   }else{

                if(_liquidityPools[poolId].token1Amount > _liquidityPools[poolId].token2Amount){
                           token1TenThousand = (_liquidityPools[poolId].token1Amount *10000) / (_liquidityPools[poolId].token1Amount + 
                           _liquidityPools[poolId].token2Amount);
                           token2TenThousand = 10000 - token1TenThousand;
                       }else{
                        token2TenThousand = (_liquidityPools[poolId].token2Amount *10000) / (_liquidityPools[poolId].token1Amount + 
                           _liquidityPools[poolId].token2Amount);
                           token1TenThousand = 10000 - token2TenThousand;
                       }
                       calculatedToken2Amount = ( (token1Amount * 10000) / token1TenThousand) - token1Amount;
                       if(calculatedToken2Amount> token2Amount){
                           calculatedToken1Amount = ( (token2Amount * 10000) / token2TenThousand) - token2Amount;
                           calculatedToken2Amount = token2Amount;
                       }else{
                           calculatedToken1Amount = token1Amount;
                       }
                   }
                       return(calculatedToken1Amount,calculatedToken2Amount);
            }

            function addLiqudityProvider(uint256 calculatedToken1Amount,uint256 calculatedToken2Amount,
            address token1ContractAdress,address token2ContractAdress, bytes memory poolId )
             private returns(bool) {
                   uint256 token1BalanceBefore;
                   uint256 token2BalanceBefore;
                   uint256 token1Balanceafter;
                   uint256 token2Balanceafter;
                       token1BalanceBefore= IERC20(token1ContractAdress).balanceOf(address(this)) ;
                       token2BalanceBefore= IERC20(token2ContractAdress).balanceOf(address(this)) ;
                       IERC20(token1ContractAdress).transferFrom(msg.sender,address(this),calculatedToken1Amount);
                       IERC20(token2ContractAdress).transferFrom(msg.sender,address(this),calculatedToken2Amount);
                       token1Balanceafter= IERC20(token1ContractAdress).balanceOf(address(this)) ;
                       token2Balanceafter= IERC20(token2ContractAdress).balanceOf(address(this)) ;
                       _liquidityPools[poolId].token1Amount +=(token1Balanceafter - token1BalanceBefore);
                       _liquidityPools[poolId].token2Amount +=(token2Balanceafter - token2BalanceBefore);
                       

                       if((token1Balanceafter-token1BalanceBefore)< calculatedToken1Amount){
                           LackOfReceivedTokens[token1ContractAdress].allTokenSended = calculatedToken1Amount ;
                           LackOfReceivedTokens[token1ContractAdress].allTokenreceived = token1Balanceafter-token1BalanceBefore ;
                       }
                       if((token2Balanceafter-token2BalanceBefore)< calculatedToken2Amount){
                           LackOfReceivedTokens[token2ContractAdress].allTokenSended = calculatedToken2Amount ;
                           LackOfReceivedTokens[token2ContractAdress].allTokenreceived = token2Balanceafter-token2BalanceBefore ;

                       }
                       if(_userLiquidity[msg.sender].isPoolAddedBefore[poolId]== false){
                           _userLiquidity[msg.sender].userPools.push(poolId);
                           _liquidityPools[poolId].liquidityproviders.push(msg.sender);
                           _userLiquidity[msg.sender].isPoolAddedBefore[poolId]= true;
                       }
                       _userLiquidity[msg.sender].token1Inpool[poolId] += (token1Balanceafter - token1BalanceBefore);
                       _userLiquidity[msg.sender].token2Inpool[poolId] += (token2Balanceafter - token2BalanceBefore);
                       tokensInfo[token1ContractAdress].tokensBalance += (token1Balanceafter - token1BalanceBefore);
                       tokensInfo[token2ContractAdress].tokensBalance += (token2Balanceafter - token2BalanceBefore);

                       emit addLiquidity(msg.sender, token1ContractAdress,token2ContractAdress,calculatedToken1Amount,calculatedToken2Amount);
                       return(true);
            }

    //AddLiquidity fuction check if the pool is not created before create it and if its created before
    // will add liquidity to pool

        function AddLiquidity(address token1ContractAdress,uint256 token1Amount
        ,address token2ContractAdress,uint256 token2Amount) public returns(string memory){
            if(IERC20(token1ContractAdress).allowance(msg.sender,address(this)) >= token1Amount && 
               IERC20(token2ContractAdress).allowance(msg.sender,address(this)) >= token2Amount ){

                   uint256 calculatedToken1Amount;
                   uint256 calculatedToken2Amount;
                   
                   // the folowing code check exiting liqudity
                   if(_liquidityPools[abi.encode(token1ContractAdress,token2ContractAdress)].isPoolCreated == true){ 
                       // this code check for any pool created for this peer
                       (calculatedToken1Amount,calculatedToken2Amount)= 
                       calculateTokenRateForAddLiqudity(token1Amount,token2Amount,abi.encode(token1ContractAdress,token2ContractAdress));
                       addLiqudityProvider(calculatedToken1Amount,calculatedToken2Amount,
                       token1ContractAdress,token2ContractAdress,abi.encode(token1ContractAdress,token2ContractAdress) );

                   }else{

                        if(_liquidityPools[abi.encode(token2ContractAdress,token1ContractAdress)].isPoolCreated == true){
                           (calculatedToken1Amount,calculatedToken2Amount)=
                           calculateTokenRateForAddLiqudity(token2Amount,token1Amount,abi.encode(token2ContractAdress,token1ContractAdress));
                           addLiqudityProvider(calculatedToken1Amount,calculatedToken2Amount,
                           token2ContractAdress,token1ContractAdress,abi.encode(token2ContractAdress,token1ContractAdress) );
                        }else{
                            bytes memory poolName;
                            address token1_C;
                            address token2_C;

                            poolName = createPool(token1ContractAdress,token2ContractAdress);
                            (token1_C,token2_C)=ConvertIDToContractAddress(poolName);
                            if(token1_C ==token1ContractAdress){
                            addLiqudityProvider( token1Amount,token2Amount,token1ContractAdress,
                            token2ContractAdress,poolName);
                            }else{
                            addLiqudityProvider( token2Amount,token1Amount,token1_C,token2_C,poolName);
                            }
                        }
                   }
                   return "sucsses";

               }else{
                   return "please approve first";
               }
        }

        function swapDirectRoutingFinder(address token1,address token2) private view returns(bytes memory,bool){
            if(_liquidityPools[abi.encode(token1,token2)].isPoolCreated==true){
                return (abi.encode(token1,token2),true);
            }else{
                if(_liquidityPools[abi.encode(token2,token1)].isPoolCreated ==true ){
                    return (abi.encode(token2,token1),true);
                }else{
                    return (abi.encode(),false);
                }
            }
        }
        function swapCalculatePriceForDirectRouting(bytes memory routeId,address tokenforSell,uint256 amountForSell) view private returns(uint256, uint256){
            address token1InPair;
            address token2InPair;
            uint256 tokenForSellInPool;
            uint256 tokenForBuyInPool;
            uint256 divided = 100;
            uint256 amountForBuy;
            uint256 AmountNotSold;
            (token1InPair,token2InPair)= ConvertIDToContractAddress(routeId);
            if(token1InPair== tokenforSell){
                tokenForSellInPool=_liquidityPools[routeId].token1Amount;
                tokenForBuyInPool=_liquidityPools[routeId].token2Amount;
            }else{
                tokenForSellInPool=_liquidityPools[routeId].token2Amount;
                tokenForBuyInPool=_liquidityPools[routeId].token1Amount;
            }
            for(uint i=0; amountForSell > 0;i++){
                if((tokenForSellInPool/divided) > amountForSell){
                    for(uint j=0; (tokenForSellInPool/divided) > amountForSell;j++ ){
                        divided *=10;
                    }
                }
                if((tokenForBuyInPool/divided) >0 ){
                    uint256 min =(tokenForSellInPool/divided);
                    uint256 plus= (tokenForBuyInPool/divided) ;
                    amountForSell-= min ;
                    amountForBuy+= plus;
                    tokenForSellInPool+=min;
                    tokenForBuyInPool -=plus;
                }else{
                    AmountNotSold = amountForSell;
                    amountForSell =0;
                }
            }
            return (amountForBuy, AmountNotSold);
        }
        function swapIntermediaryRoutingFinder(address tokenForSell, address tokenForBuy) private view returns(address [] memory){
            address [] memory intermediaryToken;
            uint count;
            for(uint i=0;tokensInfo[tokenForSell].poolsForThisToken.length>i;i++ ){
            address PairToken=convertIDToOppositeContractAdress(tokensInfo[tokenForSell].poolsForThisToken[i],tokenForSell);
                for(uint j =0;tokensInfo[tokenForBuy].poolsForThisToken.length>j;j++){
                    address PairToken2=convertIDToOppositeContractAdress(tokensInfo[tokenForBuy].poolsForThisToken[j],tokenForBuy);
                    if(PairToken == PairToken2){
                        intermediaryToken[count] =PairToken;
                        count++;
                    }
                }
            }
            return (intermediaryToken);
        }
        function swapcalculatePriceForIntermediary(address [] memory intermediaryToken) public view returns(uint256 [] memory, uint256[] memory ){
            uint256 [] memory amountRecivedPair1;
            uint256 [] memory AmountNotSoldPair1;
            uint256 [] memory amountRecivedPair2;
            uint256 [] memory AmountNotSoldPair2;
            bool b;
            bool bb;
            bytes memory routeId;
            bytes memory routeId2;
            if(intermediaryToken.length > 0){
                for(uint i=0; intermediaryToken.length>i;i++ ){
                    (routeId,b)=swapDirectRoutingFinder(intermediaryToken[i],swapS[SI].tokenForBuy);
                    (routeId2,bb)=swapDirectRoutingFinder(intermediaryToken[i],  swapS[SI].tokenForSell);
                (amountRecivedPair1[i],AmountNotSoldPair1[i])=swapCalculatePriceForDirectRouting(routeId2,swapS[SI].tokenForSell,swapS[SI].amountForSell);
                (amountRecivedPair2[i],AmountNotSoldPair2[i])=swapCalculatePriceForDirectRouting(routeId,intermediaryToken[i],amountRecivedPair1[i]);
                }
                return (amountRecivedPair2,AmountNotSoldPair1);
            }else{ return (amountRecivedPair2,AmountNotSoldPair1); }
        }
        function swapIndirectRoutingFinder() private view returns(address [] memory,address [] memory){
            address [] memory intermediaryToken1;
            address [] memory intermediaryToken2;
            
            uint count;
            for(uint i=0;tokensInfo[swapS[SI].tokenForSell].poolsForThisToken.length>i;i++ ){
            address token1Inpair;
            address token2Inpair;
            address PairToken;

            (token1Inpair,token2Inpair) = ConvertIDToContractAddress(tokensInfo[swapS[SI].tokenForSell].poolsForThisToken[i]);
            if(token1Inpair == swapS[SI].tokenForSell){
                PairToken = token2Inpair;
            }else{
                PairToken = token1Inpair;
            }
                for(uint j =0;tokensInfo[swapS[SI].tokenForBuy].poolsForThisToken.length>j;j++){

                    address token1Inpair2;
                    address token2Inpair2;
                    address PairToken2;
                    bytes memory directRouteReciver ;
                    bool isRouteFound = false;
                    (token1Inpair2,token2Inpair2) = ConvertIDToContractAddress(tokensInfo[swapS[SI].tokenForBuy].poolsForThisToken[j]);
                    if(token1Inpair2 == swapS[SI].tokenForBuy){
                    PairToken2 = token2Inpair2;
                    }else{
                    PairToken2 = token1Inpair2;
                    (directRouteReciver,isRouteFound) = swapDirectRoutingFinder(PairToken,PairToken2);
                    if(isRouteFound == true){
                        intermediaryToken1[count]=PairToken;
                        intermediaryToken2[count]=PairToken2;
                        count++;
                    }
                }
                }
            }
            return (intermediaryToken1,
            intermediaryToken2);
        }
        function swapcalculatePriceForIndirectRouting(address [] memory intermediaryToken1,address [] memory intermediaryToken2)
        private view returns(uint256 [] memory, uint256[] memory ){
            bytes [] memory intermediary1PairId;
            bytes [] memory intermediary2PairId;
            bytes [] memory intermediary3PairId;
            bool b;
            
            uint256 [] memory amountRecivedPair1;
            uint256 [] memory AmountNotSoldPair1;
            uint256 [] memory amountRecivedPair2;
            uint256 AmountNotSoldPair2;
            uint256 [] memory amountRecivedPair3;
            
                for(uint i=0;intermediary1PairId.length > i;i++ ){
                    (intermediary1PairId[i],b) = swapDirectRoutingFinder(swapS[SI].tokenForSell,intermediaryToken1[i]);
                    (intermediary2PairId[i],b) = swapDirectRoutingFinder(intermediaryToken2[i],intermediaryToken1[i]);
                    (intermediary3PairId[i],b) = swapDirectRoutingFinder(intermediaryToken2[i],swapS[SI].tokenForBuy);
                    
                (amountRecivedPair1[i],AmountNotSoldPair1[i])=swapCalculatePriceForDirectRouting(intermediary1PairId[i],swapS[SI].tokenForSell,swapS[SI].amountForSell);
                (amountRecivedPair2[i],AmountNotSoldPair2)=swapCalculatePriceForDirectRouting(intermediary2PairId[i],intermediaryToken1[i],amountRecivedPair1[i]);
                (amountRecivedPair3[i],AmountNotSoldPair2)=swapCalculatePriceForDirectRouting(intermediary3PairId[i],intermediaryToken2[i],amountRecivedPair2[i]);
                }
                return (amountRecivedPair3,AmountNotSoldPair1);
            
        }
        function findLargestNumberInUnitArry(uint256 [] memory num) pure private returns (uint256,uint){
            uint256 largestNumber;
            uint index;
            for(uint i=0;num.length>i;i++){
                if(num[i]>largestNumber){
                    largestNumber = num[i];
                    index=i;
                }
            }
            return (largestNumber,index);
        }
        bytes emptyBiytes;
        address emptyAddress;
       
        
        function findSwapRoutesAndPrice()private view  returns(uint256,uint256,address,address,uint){
            (bytes memory DirectRouteId,bool isDirectRouteFind) =
            swapDirectRoutingFinder(swapS[SI].tokenForSell,swapS[SI].tokenForBuy);
            uint256 BestPrice;
            uint256 tokenNotSoldFinal;
            address finalIntermediaryToken1;
            address finalIntermediaryToken2;
            uint swapType;

            if(isDirectRouteFind==true){
                (uint256 tokenCanBuy,uint256 tokenNotSold)=
                swapCalculatePriceForDirectRouting(DirectRouteId,swapS[SI].tokenForSell,swapS[SI].amountForSell);
                if(tokenCanBuy > BestPrice){
                BestPrice =tokenCanBuy;
                tokenNotSoldFinal=tokenNotSold;
                finalIntermediaryToken1=emptyAddress;
                finalIntermediaryToken2=emptyAddress;
                swapType=0;
                }
            }
            (address [] memory IntermediaryToken)=
            swapIntermediaryRoutingFinder(swapS[SI].tokenForSell,swapS[SI].tokenForBuy);
            if(IntermediaryToken.length> 0){
                (uint256 [] memory tokenCanBuyIntermediary, uint256[] memory tokenNotSoldIntermediary)=
                swapcalculatePriceForIntermediary(IntermediaryToken);
                (uint256 IntermediaryBestPrice,uint IntermediaryIndex )= findLargestNumberInUnitArry(tokenCanBuyIntermediary);
                if(IntermediaryBestPrice > BestPrice ){
                BestPrice =IntermediaryBestPrice;
                tokenNotSoldFinal=tokenNotSoldIntermediary[IntermediaryIndex];
                finalIntermediaryToken1=IntermediaryToken[IntermediaryIndex];
                finalIntermediaryToken2=emptyAddress;
                swapType=1;

                }

            }
            (address [] memory indirectToken1,address [] memory indirectToken2)= swapIndirectRoutingFinder();
            if(indirectToken1.length > 0  ){
                (uint256 [] memory TokenCanBuyindirect, uint256[] memory indirectNotSold )=
                swapcalculatePriceForIndirectRouting(indirectToken1,indirectToken2);
                (uint256 IndirectBestPrice,uint IndirectIndex )= findLargestNumberInUnitArry(TokenCanBuyindirect);
                if(IndirectBestPrice > BestPrice ){
                BestPrice =IndirectBestPrice;
                tokenNotSoldFinal=indirectNotSold[IndirectIndex];
                finalIntermediaryToken1=indirectToken1[IndirectIndex];
                finalIntermediaryToken2=indirectToken2[IndirectIndex];
                swapType=2;
                }
            }
            return (BestPrice,tokenNotSoldFinal,finalIntermediaryToken1,finalIntermediaryToken2,swapType);
        }
       
        function calculatePlatformFeeAndLiqudityProviderFee(uint256 amountTokenForSell) private view returns(uint256,uint256){
            uint256 _platformFee= (swapPatformFee * amountTokenForSell) / 10000;
            uint256 _liquidityproviderFee = amountTokenForSell  * liquidityprovidersFee /10000;
            return (_platformFee,_liquidityproviderFee);
        }

        event doTrade1(uint256 token1amount, uint256 liqudityProviderL, address token1InPair,address token2InPair);

        function doTrade(address tokenForSell , uint256 amountForSwap,uint256 amountForBuy, uint256 AmountNotSold,bytes memory id ) private returns(bool){
             (address token1InPair,address token2InPair)= ConvertIDToContractAddress(id);
                    if(token1InPair== tokenForSell){
                       //emit doTrade1( _liquidityPools[id].token1Amount,_liquidityPools[id].liquidityproviders.length,  token1InPair, token2InPair);
                    _liquidityPools[id].token1Amount+=(amountForSwap - AmountNotSold)   ; //tokenForSellInPool
                    
                     emit doTrade1( _liquidityPools[id].token1Amount,_liquidityPools[id].liquidityproviders.length,  token1InPair, token2InPair);
                    
                    for(uint i;_liquidityPools[id].liquidityproviders.length >i;i++ ){
                     
                       
                       _userLiquidity[_liquidityPools[id].liquidityproviders[i]].tokenRewards[swapS[SI].tokenForSell]+=

                        (_userLiquidity[_liquidityPools[id].liquidityproviders[i]].token1Inpool[id] * swapS[SI].liquidityproviderFee) / 
                        _liquidityPools[id].token1Amount ;

                        _userLiquidity[_liquidityPools[id].liquidityproviders[i]].token1Inpool[id] =
                         (_liquidityPools[id].token1Amount * _userLiquidity[_liquidityPools[id].liquidityproviders[i]].token1Inpool[id]) /
                          (_liquidityPools[id].token1Amount - (amountForSwap - AmountNotSold)) ;
                    }
                    
                    _liquidityPools[id].token2Amount-=amountForBuy;  //tokenForBuyInPool
                    }else{
                        _liquidityPools[id].token2Amount+=(amountForSwap - AmountNotSold); //tokenForSellInPool

                       
                    for(uint i;_liquidityPools[id].liquidityproviders.length >i;i++ ){
                       // _liquidityPools[id].liquidityproviders[i];
                       //_liquidityPools[id].divideRemainingToken1 +=
                       //token1Rewards
                       _userLiquidity[_liquidityPools[id].liquidityproviders[i]].tokenRewards[swapS[SI].tokenForSell]+=
                        (_userLiquidity[_liquidityPools[id].liquidityproviders[i]].token2Inpool[id] * swapS[SI].liquidityproviderFee) / 
                        _liquidityPools[id].token2Amount ;

                        _userLiquidity[_liquidityPools[id].liquidityproviders[i]].token2Inpool[id] =
                         (_liquidityPools[id].token2Amount * _userLiquidity[_liquidityPools[id].liquidityproviders[i]].token2Inpool[id]) /
                          (_liquidityPools[id].token2Amount - (amountForSwap - AmountNotSold)) ;
                    }
                         _liquidityPools[id].token1Amount-=amountForBuy; //tokenForBuyInPool
                    }
        }
        event doSwapDebug2 (bytes pairId, bool b, uint256 amountForBuy, uint256 AmountNotSold);
        //event doSwapDebug3 (uint256 tokenBalanceBefore  , uint256 tokenBalanceafter);

        event doSwapDebug (uint256 amountForSwap,uint256 liqudityFee,uint256 platformFee,uint SwapType,bytes pairId );
        
        function doSwap(uint256 minAmountToBuy) private returns(bool){
            swapS[SI].amountForSwap = swapS[SI].amountForSell - (swapS[SI].liquidityproviderFee + swapS[SI].platformFee);
            bool b;
            emit doSwapDebug (swapS[SI].amountForSwap,swapS[SI].liquidityproviderFee,swapS[SI].platformFee,swapS[SI].swaptype,swapS[SI].intermediary1PairId );

            if(swapS[SI].swaptype==0 ){
                (swapS[SI].intermediary1PairId ,b)=
                swapDirectRoutingFinder(swapS[SI].tokenForSell,swapS[SI].tokenForBuy);
                
                (uint256 amountForBuy, uint256 AmountNotSold)= swapCalculatePriceForDirectRouting(swapS[SI].intermediary1PairId,swapS[SI].tokenForSell,swapS[SI].amountForSwap);
                emit doSwapDebug2 (swapS[SI].intermediary1PairId,b,  amountForBuy,  AmountNotSold);
                if(amountForBuy >= minAmountToBuy ){
                    uint256 tokenBalanceBefore =  IERC20(swapS[SI].tokenForSell).balanceOf(address(this));
                     IERC20(swapS[SI].tokenForSell).transferFrom(msg.sender,address(this),(swapS[SI].amountForSell-AmountNotSold));//address sender, address recipient, uint256 amount
                    uint256 tokenBalanceafter =IERC20(swapS[SI].tokenForSell).balanceOf(address(this));
                    //emit doSwapDebug3 (tokenBalanceBefore,tokenBalanceafter);
                    if ((tokenBalanceafter-tokenBalanceBefore) < swapS[SI].amountForSell ){
                        swapS[SI].amountForSell ==(tokenBalanceafter-tokenBalanceBefore);
                        (swapS[SI].platformFee,swapS[SI].liquidityproviderFee)=
                        calculatePlatformFeeAndLiqudityProviderFee(swapS[SI].amountForSell);
                        swapS[SI].amountForSwap= swapS[SI].amountForSell - (swapS[SI].liquidityproviderFee + swapS[SI].platformFee);
                        (amountForBuy,AmountNotSold)=
                        swapCalculatePriceForDirectRouting(swapS[SI].intermediary1PairId,swapS[SI].tokenForSell,swapS[SI].amountForSwap);
                    }
                    doTrade(swapS[SI].tokenForSell ,swapS[SI].amountForSwap,amountForBuy,AmountNotSold,swapS[SI].intermediary1PairId);
                    IERC20(swapS[SI].tokenForBuy).transfer(msg.sender,amountForBuy);
                    //emit _swap(msg.sender, address(this),msg.sender, swapS[SI].amountForSell-AmountNotSold,amountForBuy);
                }
            }

            if(swapS[SI].swaptype==1){

                 (swapS[SI].intermediary1PairId ,b)=
                swapDirectRoutingFinder(swapS[SI].tokenForSell,swapS[SI].intermediaryToken1);
                (swapS[SI].intermediary2PairId ,b)=
                swapDirectRoutingFinder(swapS[SI].intermediaryToken1,swapS[SI].tokenForBuy);
                
                (uint256 amountForBuy, uint256 AmountNotSold)= swapCalculatePriceForDirectRouting(swapS[SI].intermediary1PairId,swapS[SI].tokenForSell,swapS[SI].amountForSwap);
                (uint256 amountForBuy2, uint256 AmountNotSold2)= swapCalculatePriceForDirectRouting(swapS[SI].intermediary2PairId,swapS[SI].intermediaryToken1,amountForBuy);


                if(amountForBuy2 >= minAmountToBuy ){

                    uint256 tokenBalanceBefore =  IERC20(swapS[SI].tokenForSell).balanceOf(address(this));

                    bool transferFromSender= IERC20(swapS[SI].tokenForSell).transferFrom(msg.sender,address(this),(swapS[SI].amountForSell-AmountNotSold));//address sender, address recipient, uint256 amount
                    if(transferFromSender==true){

                    uint256 tokenBalanceafter =IERC20(swapS[SI].tokenForSell).balanceOf(address(this));

                    if ((tokenBalanceafter-tokenBalanceBefore) < swapS[SI].amountForSell ){

                        swapS[SI].amountForSell ==(tokenBalanceafter-tokenBalanceBefore);
                        (swapS[SI].platformFee,swapS[SI].liquidityproviderFee)=
                        calculatePlatformFeeAndLiqudityProviderFee(swapS[SI].amountForSell);
                        swapS[SI].amountForSwap= swapS[SI].amountForSell - (swapS[SI].liquidityproviderFee + swapS[SI].platformFee);
                        (amountForBuy,AmountNotSold)=
                        swapCalculatePriceForDirectRouting(swapS[SI].intermediary1PairId,swapS[SI].tokenForSell,swapS[SI].amountForSwap);
                        ( amountForBuy2,  AmountNotSold2)=
                         swapCalculatePriceForDirectRouting(swapS[SI].intermediary2PairId,swapS[SI].intermediaryToken1,amountForBuy);
                    }
                    doTrade(swapS[SI].tokenForSell,swapS[SI].amountForSwap,amountForBuy,AmountNotSold,swapS[SI].intermediary1PairId);
                    doTrade(swapS[SI].intermediaryToken1,amountForBuy,amountForBuy2,AmountNotSold,swapS[SI].intermediary2PairId);

                    
                    IERC20(swapS[SI].tokenForSell).transfer(msg.sender,amountForBuy);
                    emit _swap(msg.sender, address(this),msg.sender, swapS[SI].amountForSell-AmountNotSold,amountForBuy2);
                    }
                }
            }
            
                if(swapS[SI].swaptype==2){
                    (swapS[SI].intermediary1PairId , b)=
                    swapDirectRoutingFinder(swapS[SI].tokenForSell,swapS[SI].intermediaryToken1);
                    (swapS[SI].intermediary2PairId , b)=
                    swapDirectRoutingFinder(swapS[SI].intermediaryToken1,swapS[SI].intermediaryToken2);
                    (swapS[SI].intermediary3PairId , b)=
                    swapDirectRoutingFinder(swapS[SI].intermediaryToken2,swapS[SI].tokenForBuy);
                
                    (uint256 amountForBuy, uint256 AmountNotSold)= swapCalculatePriceForDirectRouting(swapS[SI].intermediary1PairId,swapS[SI].tokenForSell,swapS[SI].amountForSwap);
                    (uint256 amountForBuy2, uint256 AmountNotSold2)= swapCalculatePriceForDirectRouting(swapS[SI].intermediary2PairId,swapS[SI].intermediaryToken1,amountForBuy);
                    (uint256 amountForBuy3, uint256 AmountNotSold3)= swapCalculatePriceForDirectRouting(swapS[SI].intermediary3PairId,swapS[SI].intermediaryToken2,amountForBuy2);

                    if(amountForBuy3 >= minAmountToBuy ){

                        uint256 tokenBalanceBefore =  IERC20(swapS[SI].tokenForSell).balanceOf(address(this));

                        bool transferFromSender= IERC20(swapS[SI].tokenForSell).transferFrom(msg.sender,address(this),(swapS[SI].amountForSell-AmountNotSold));//address sender, address recipient, uint256 amount
                        if(transferFromSender==true){

                            uint256 tokenBalanceafter =IERC20(swapS[SI].tokenForSell).balanceOf(address(this));

                            if ((tokenBalanceafter-tokenBalanceBefore) < swapS[SI].amountForSell ){

                                swapS[SI].platformFee+=(tokenBalanceafter-tokenBalanceBefore) - swapS[SI].amountForSell;
                                
                            }
                            doTrade(swapS[SI].tokenForSell,swapS[SI].amountForSwap,amountForBuy,AmountNotSold,swapS[SI].intermediary1PairId);
                            doTrade(swapS[SI].intermediaryToken1,amountForBuy,amountForBuy2,AmountNotSold,swapS[SI].intermediary2PairId);
                            doTrade(swapS[SI].intermediaryToken1,amountForBuy,amountForBuy2,AmountNotSold,swapS[SI].intermediary2PairId);

                            IERC20(swapS[SI].tokenForSell).transfer(msg.sender,amountForBuy);
                            emit _swap(msg.sender, address(this),msg.sender, swapS[SI].amountForSell-AmountNotSold,amountForBuy2);
                        }

                    }
                }
        }
        event swapDebuging(uint counter, uint256 amountForSell,uint SI,address tokenForSell,address tokenForBuy,uint256 bestPrice,uint256 tokenNotSold  );

        function swap(address tokenForSellContractAddress, address tokenForBuyContractAddress,uint256 amountTokenForSell,uint256 minAmountToBuy)
        public returns(uint256, bool){
            if(tokensInfo[tokenForSellContractAddress].isSubmitedBefore==true && tokensInfo[tokenForBuyContractAddress].isSubmitedBefore == true){
                if(tokenForSellContractAddress != tokenForBuyContractAddress){
                    swapS[SI].tokenForSell = tokenForSellContractAddress;
                    swapS[SI].tokenForBuy = tokenForBuyContractAddress;
                    swapS[SI].amountForSell = amountTokenForSell;
                    (swapS[SI].bestPrice,swapS[SI].tokenNotSold,swapS[SI].intermediaryToken1,swapS[SI].intermediaryToken2,swapS[SI].swaptype)=
                    findSwapRoutesAndPrice();
                    (swapS[SI].platformFee,swapS[SI].liquidityproviderFee)=
                    calculatePlatformFeeAndLiqudityProviderFee(amountTokenForSell);
                    emit swapDebuging (1, swapS[SI].amountForSell,SI,swapS[SI].tokenForSell,swapS[SI].tokenForBuy,swapS[SI].bestPrice,swapS[SI].tokenNotSold);  
                    doSwap(minAmountToBuy);
                    SI++;
                }else{
                    return(0,false);
                }

            }else{
                return (0,false);
            }
            
        }
        function liquidityprovidersFeeChanger(uint256 newFee) public onlyOwner returns(bool){
            liquidityprovidersFee = newFee;
            return true;
        }
        function PlatformFeeChanger(uint256 newFee) public onlyOwner returns(bool){
            swapPatformFee = newFee;
            return true;
        }
        uint256 allTokenSubmitedCount;//adddddd
        
        uint256 SI;
        struct allSwapSubmited{
             address tokenForSell;
             address tokenForBuy;
             uint256 amountForSell;
             uint256 NumberOfTokensPurchased;
             bytes intermediary1PairId;
             bytes intermediary2PairId;
             bytes intermediary3PairId;
             address intermediaryToken1; 
             address intermediaryToken2;
             uint256 AmountRecieved;
             uint256 amountForSwap;// its will be = amountForSell- fees
             uint256 platformFee;
             uint256 liquidityproviderFee;
             uint swaptype;
             uint256 bestPrice;
             uint256 tokenNotSold;
             bytes tokenSwapId; // its create by abi.encode of token for sell contract address and token for buy contract address
        }

        uint256 public liquidityprovidersFee;
        uint256 public swapPatformFee;

        struct AllTokenInfo{
            string tokenName;
            string tokenSymbol;
            IERC20 tokenContractAddress;
            uint256 tokensBalance;
            uint8  decimals;
            bool isSubmitedBefore;
            bytes [] poolsForThisToken;
            uint256 DivideRemaining;
        }
        struct usersLiquidity{
            mapping (bytes => uint256) token1Inpool;
            bytes [] userPools;
            mapping (bytes => uint256) token2Inpool;
            mapping (bytes => bool) isPoolAddedBefore;
            mapping (address => uint256) tokenRewards;
            
        }
        struct liquidityPools{
            string pairName;
            uint256 token1Amount;
            uint256 token2Amount;
            bool isPoolCreated;
            address[] liquidityproviders;
            uint256 token1PlatformFee;
            uint256 token2PlatformFee;
            
        }
        struct tokenWithPercentageDeficit{
            uint256 allTokenSended;
            uint256 allTokenreceived;
   
        }
    
          mapping (address => AllTokenInfo) tokensInfo;

          mapping (address => usersLiquidity) _userLiquidity; 

          mapping (bytes => liquidityPools) _liquidityPools;

          mapping (address => bool)IsStableCoin;

          mapping (address => tokenWithPercentageDeficit)LackOfReceivedTokens;
          
          mapping (uint256 => allSwapSubmited) swapS;

          mapping(uint256 => address )allTokenSubmited;

}