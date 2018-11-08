pragma solidity ^0.4.0;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract vietlot is usingOraclize {
    address public manager;
    address public winner;
    uint private generatedNumber;
    uint public totalPlayer = 0;
    bool public isFinished = false;
    address[] player;
    
    constructor () public {
        manager = msg.sender;
    }
    
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }
    
    modifier notManager {
        require(msg.sender != manager);
        _;
    }
    
    modifier notFinished {
        require(isFinished == false);
        _;
    }
    
    // Alow user other than manager can play Vietlol
    // Remember that an address can play any times they want
    // So the more time they play, the higher ratio they can win the game
    function play() public notManager {
        player.push(msg.sender);
        totalPlayer ++;
    }
    
    // show list player, note that an address can play more than 1 time
    function listPlayer() public constant returns(address[]) {
        return player;
    }
    
    // Use generated number to choose a winner
    function chooseWinner(uint randomNumber) internal {
        winner = player[randomNumber];
    }
    
    // delete all data and start a new game
    function startNewGame() public onlyManager {
        isFinished = false;
        totalPlayer = 0;
        delete player;
        delete winner;
    }
    
    // Generate a random number 
    function generateRandomNumber() public onlyManager {
        oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof
        uint N = 4; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 200000; // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId
    }
    
    // Send eth to contract address, so it can generate random number using Oraclize library
    function () payable {}
    
    // the callback function is called by Oraclize when the result is ready
    // the oraclize_randomDS_proofVerify modifier prevents an invalid proof to execute this function code:
    // the proof validity is fully verified on-chain
    function __callback(bytes32 _queryId, string _result, bytes _proof)
    {
      // If we already generated a random number, we can't generate a new one.
      require(isFinished == false);
      // if we reach this point successfully, it means that the attached authenticity proof has passed!
      require (msg.sender == oraclize_cbAddress());
      if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
        // the proof verification has failed, do we need to take any action here? (depends on the use case)
      } else {
        // the proof verification has passed
        isFinished = true;
        // for simplicity of use, let's also convert the random bytes to uint if we need
        uint maxRange = totalPlayer - 1; // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
        uint randomNumber = uint(sha3(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
        
        chooseWinner(randomNumber);
      }
}
}
