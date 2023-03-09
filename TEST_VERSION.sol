//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**************************************************
*  __                  __      __                 *
* |  \                |  \    |  \                *
* | $$       ______  _| $$_  _| $$_     ______    *
* | $$      /      \|   $$ \|   $$ \   /      \   *
* | $$     |  $$$$$$\\$$$$$$ \$$$$$$  |  $$$$$$\  *
* | $$     | $$  | $$ | $$ __ | $$ __ | $$  | $$  *
* | $$_____| $$__/ $$ | $$|  \| $$|  \| $$__/ $$  *
* | $$     \\$$    $$  \$$  $$ \$$  $$ \$$    $$  *
*  \$$$$$$$$ \$$$$$$    \$$$$   \$$$$   \$$$$$$   *
*                                                 *
***************************************************/

contract Lotto is Ownable {

    /***************************************/
    /*         CONSTANT VARIABLES          */
    /***************************************/

    uint256 public constant MAX_INT = 2**256 - 1;
    
    /***************************************/
    /*       CONFIGURABLE VARIABLES        */
    /***************************************/

    //the ticket price for the next round, in case it is updated
    uint64 public ticketPriceUpdate;

    //current ticket price
    uint64 public ticketPrice;

    //round duration in seconds
    uint256 public roundDuration;

    //round duration for the next round, in case it is updated
    uint256 public roundDurationUpdate;

    //cooldown duration in seconds
    uint256 public cooldownDuration;

    //cooldown duration for the next round, in case it is updated
    uint256 public cooldownDurationUpdate;

    /***************************************/
    /*           GAME VARIABLES            */
    /***************************************/

    //the current game
    uint64 public currentGame;

    //the current round
    uint64 public currentRound;

    //the size of the jackpot
    uint256 private jackpot;

    //the fees the owner has to withdraw;
    uint256 private houseFees;

    //game => round => the amount of tickets alive
    mapping(uint256 => uint256[]) public ticketsLeft;
    
    //game => round => time it started
    mapping (uint256 => uint256[]) public startedAt;

    //game => excluded numbers, 2 per round E.g.: 0 and 1 for round 1; 2 and 3 for round 2.
    mapping (uint256 => uint256[]) public excludedNumbers;

    //game => round => tickets array length
    mapping (uint256 => mapping (uint256 => uint256)) public ticketsLength;

    //game => tickets array (number and address of the owner)
    mapping (uint256 => address[]) public getTickets;
    
    //the position of all tickets owned by a certain user in a certain game
    mapping (uint256 => mapping (address => uint256[])) public getTicketsByUser;
    
    //the position of a certain ticket inside the getTicketsByUser array
    mapping (uint256 => mapping(address => mapping (uint256 => uint256))) private getTicketsPositionByUser;

    //game => [0] -> user already rolled? [1] -> round user rolled [2] -> 1st rolled number -> [3] 2nd rolled number
    mapping (uint256 => mapping(address => uint64[4])) public rolledNumbers;

    //game => payout per winning ticket, if 0 game has not ended yet
    mapping (uint256 => uint256) public payoutPerTicket;

    //game => user aleady withdrawn?
    mapping (uint256 => mapping(address => bool)) public alreadyWithdrawn;
    
    /***************************************/
    /*             CONSTRUCTOR             */
    /***************************************/
    constructor(uint64 ticketPrice_, uint256 roundDuration_, uint256 cooldownDuration_) {
        startedAt[0].push(block.timestamp);
        ticketsLeft[currentGame].push(0);
        ticketPrice = ticketPrice_;
        ticketPriceUpdate = ticketPrice_;
         //86400 == 24hrs; 3600 == 1hr; 1200 == 20 minutes
        cooldownDuration = cooldownDuration_;
        cooldownDurationUpdate = cooldownDuration_;
        roundDuration = roundDuration_;
        roundDurationUpdate = roundDuration_;
    }

    /***************************************/
    /*             BUY TICKETS             */
    /***************************************/
    function buyTickets(uint256 amount) external payable {
        require(amount*ticketPrice == msg.value, "Incorrect amount of ether");

        //still in cooldown
        require(block.timestamp >= startedAt[currentGame][currentRound], "The game hasn't started yet");

        if(currentRound == 0) {
            if(getTickets[currentGame].length == 0) {
                for(uint256 i; i < amount; i++) {
                    getTickets[currentGame].push(msg.sender);
                    getTicketsByUser[currentGame][msg.sender].push(i);
                    getTicketsPositionByUser[currentGame][msg.sender][i] = i;
                }
            } else {
                for(uint256 i = 0; i<amount; i++) {
                    uint256 rng = getRandomNumber(getTickets[currentGame].length * 2, i);
                    if(rng >= getTickets[currentGame].length) {
                        getTickets[currentGame].push(msg.sender);
                        getTicketsByUser[currentGame][msg.sender].push(getTickets[currentGame].length - 1);
                        getTicketsPositionByUser[currentGame][msg.sender][getTickets[currentGame].length - 1] = getTicketsByUser[currentGame][msg.sender].length - 1;
                    } else {
                        address temp = getTickets[currentGame][rng];
                        getTickets[currentGame][rng] = msg.sender;
                        getTickets[currentGame].push(temp);

                        getTicketsByUser[currentGame][temp][getTicketsPositionByUser[currentGame][temp][rng]] = getTickets[currentGame].length - 1;
                        getTicketsPositionByUser[currentGame][temp][getTickets[currentGame].length - 1] = getTicketsPositionByUser[currentGame][temp][rng];

                        getTicketsByUser[currentGame][msg.sender].push(rng);
                        getTicketsPositionByUser[currentGame][msg.sender][rng] = getTicketsByUser[currentGame][msg.sender].length -1;   
                    }
                }
            }
        } else {
            require(rolledNumbers[currentGame][msg.sender][0] == 0, "You can't buy more tickets if you already rolled");

            bool _ticketsAlive = false;

            for(uint256 i; i < getTicketsByUser[currentGame][msg.sender].length; i++) {
                uint256 _currentGame = currentGame;
                uint256 _ticket = getTicketsByUser[_currentGame][msg.sender][i];
                if(getTickets[_currentGame][_ticket] != address(0)) {
                    _ticketsAlive = true;
                    i = getTicketsByUser[currentGame][msg.sender].length;
                }
            }

            require(_ticketsAlive == true, "You can't buy after round 1 if none of your tickets are alive");
            
            for(uint256 i; i < amount; i++) {
                getTickets[currentGame].push(msg.sender);
                getTicketsByUser[currentGame][msg.sender].push(getTickets[currentGame].length - 1);
                getTicketsPositionByUser[currentGame][msg.sender][getTickets[currentGame].length - 1] = getTicketsByUser[currentGame][msg.sender].length - 1;
            }
        }

        houseFees = msg.value * 4 / 100;

        //jackpot share, the 25% that is rolled to the next round is handled in the endGame function
        jackpot = msg.value * 96 / 100;

        ticketsLeft[currentGame][currentRound] += amount;

        if(block.timestamp >= startedAt[currentGame][currentRound] + roundDuration) {
           uint64 rng1 = getRandomNumber(getTickets[currentGame].length, 5);
           uint64 rng2 = getRandomNumber(getTickets[currentGame].length, 9);
           finishRound(rng1, rng2);
        }
    }
    
    /***************************************/
    /*            FINISH ROUND             */
    /***************************************/
    function finishRound(uint64 rng1, uint64 rng2) public {
        require(block.timestamp >= startedAt[currentGame][currentRound] + roundDuration);
        
        uint256 _ticketsLeft = ticketsLeft[currentGame][currentRound];

        //saves current round tickets array length
        ticketsLength[currentGame][currentRound] = getTickets[currentGame].length;

        if (currentRound != 0 && _ticketsLeft <= 10) endGame();
        else if(currentRound == 9) endGame();
        else if (currentRound == 0 && _ticketsLeft == 0) abort();
        else {

            //makes sure rng1 is greater than the rng2
            if(rng1 > rng2) {
                uint64 temp = rng2;
                rng2 = rng1;
                rng1 = temp;
            }

            //saves the numbers
            excludedNumbers[currentGame].push(rng1);
            excludedNumbers[currentGame].push(rng2);

            //checks the 2 intervals
            uint256 outside = rng1 + getTickets[currentGame].length-rng2;
            uint256 inside = rng2 - rng1;

            if(outside > inside) {
                for(uint256 i = 0; i <= rng1; i++) {
                    if(getTickets[currentGame][i] != address(0)) {
                        getTickets[currentGame][i] = address(0);
                        _ticketsLeft --;
                    }
                }
                for(uint256 i = rng2; i < getTickets[currentGame].length; i++) {
                    if(getTickets[currentGame][i] != address(0)) {
                        getTickets[currentGame][i] = address(0);
                        _ticketsLeft --;
                    }
                }
            } else {
                for(uint256 i = rng1; i <= rng2; i++) {
                    if(getTickets[currentGame][i] != address(0)) {
                        getTickets[currentGame][i] = address(0);
                        _ticketsLeft --;
                    }
                }
            }
            currentRound ++;
            ticketsLeft[currentGame].push(_ticketsLeft);
            startedAt[currentGame].push(block.timestamp);
        }
    }

    /***************************************/
    /*            ROLL TICKETS             */
    /***************************************/
    function roll(uint64 rng1, uint64 rng2) public {
        require(rolledNumbers[currentGame][msg.sender][0] == 0, "You can only roll once per game");
        require(rng1 < getTickets[currentGame].length && rng2 < getTickets[currentGame].length);
        bool _canRoll = true;
        uint256 _ticketsByUserLength = getTicketsByUser[currentGame][msg.sender].length;
        for(uint256 i; i < getTicketsByUser[currentGame][msg.sender].length; i++) {
            if(getTickets[currentGame][getTicketsByUser[currentGame][msg.sender][i]] != address(0)) _canRoll = false;
        }

        require(_canRoll == true, "You can only roll if all your tickets have been eliminated");

        uint256[] memory rollableTickets;
        uint256 counter;

        if(currentRound == 1) {
            rollableTickets = getTicketsByUser[currentGame][msg.sender];
            counter = _ticketsByUserLength;
        } else {
            //gets the tickets that where still alive last round
            rollableTickets = new uint256[](_ticketsByUserLength);
            uint256[4] memory boundaries = _getBoundaries(currentGame, 0, excludedNumbers[currentGame].length - 2);
            uint256 roundCounter;
            uint256 i;
            while (i < _ticketsByUserLength) {
                uint256 ticket = getTicketsByUser[currentGame][msg.sender][i];

                if(ticket < ticketsLength[currentGame][roundCounter]) {
                    if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                        rollableTickets[counter] = ticket;
                        counter++;
                    }
                    i++;
                } else if (ticket < ticketsLength[currentGame][roundCounter +1]){
                    roundCounter ++;
                    boundaries = _getBoundaries(currentGame, roundCounter, excludedNumbers[currentGame].length - 2);
                    if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                        rollableTickets[counter] = ticket;
                        counter++;
                    }
                    i++;
                } else {
                    roundCounter ++;
                }
            }
        }

        require(counter != 0, "You have no tickets to roll");

        //gets 2 random numbers
       
        //makes sure rng1 is greater than the rng2
        if(rng1 > rng2) {
            uint64 temp = rng2;
            rng2 = rng1;
            rng1 = temp;
        }

        //checks the 2 intervals
        uint256 outside = rng1 + getTickets[currentGame].length-rng2;
        uint256 inside = rng2 - rng1;

        uint256 _ticketsLeft = ticketsLeft[currentGame][currentRound];

        if(outside > inside) {
            for(uint256 i; i < counter; i++) {
                if(rollableTickets[i] > rng1 && rollableTickets[i] < rng2) {
                    getTickets[currentGame][rollableTickets[i]] = msg.sender;
                    _ticketsLeft ++;
                }
            }
        } else {
            for(uint256 i; i < counter; i++) {
                if(rollableTickets[i] < rng1 && rollableTickets[i] > rng2) {
                    getTickets[currentGame][rollableTickets[i]] = msg.sender;
                    _ticketsLeft++;
                }
            }
        }

        ticketsLeft[currentGame][currentRound] = _ticketsLeft;
        rolledNumbers[currentGame][msg.sender] = [1, currentRound, rng1, rng2];
    }

    /***************************************/
    /*              END GAME               */
    /***************************************/
    function endGame() private {
        uint256 rollOver;
        uint256 payouts;

        //roll over 25% to the next pot (96 * 26% = 24.96%) and pays out the rest
        rollOver = jackpot * 26 / 100;
        payouts = jackpot - rollOver;
        jackpot = rollOver;
        
        if(ticketsLeft[currentGame][currentRound] == 0) {
            payoutPerTicket[currentGame] = payouts / ticketsLeft[currentGame][currentRound - 1];
        } else {
            payoutPerTicket[currentGame]  = payouts / ticketsLeft[currentGame][currentRound];
        }

        //start next game, resets round and ticketsLeft to 0
        currentGame ++;
        currentRound = 0;
        startedAt[currentGame].push(block.timestamp + cooldownDuration);
        ticketsLeft[currentGame].push(0);
        //if the ticket price has been updated, set the new ticket price for the next round
        if(ticketPrice != ticketPriceUpdate) {
            ticketPrice = ticketPriceUpdate;
        }

        //if the round duration has been updated, set the new round duration for the next round
        if(roundDuration != roundDurationUpdate) {
            roundDuration = roundDurationUpdate;
        }

        //if the cooldown duration has been updated, set the new cooldown duration for the next round
        if(cooldownDuration != cooldownDurationUpdate) {
            cooldownDuration = cooldownDurationUpdate;
        }
    }

    /***************************************/
    /*             ABORT GAME              */
    /***************************************/
    function abort() private {
        //start next game, resets round and ticketsLeft to 0
        currentGame ++;
        currentRound = 0;
        startedAt[currentGame].push(block.timestamp + cooldownDuration);
        ticketsLeft[currentGame].push(0);
        //if the ticket price has been updated, set the new ticket price for the next round
        if(ticketPrice != ticketPriceUpdate) {
            ticketPrice = ticketPriceUpdate;
        }

        //if the round duration has been updated, set the new round duration for the next round
        if(roundDuration != roundDurationUpdate) {
            roundDuration = roundDurationUpdate;
        }

        //if the cooldown duration has been updated, set the new cooldown duration for the next round
        if(cooldownDuration != cooldownDurationUpdate) {
            cooldownDuration = cooldownDurationUpdate;
        }
    }

    /***************************************/
    /*          WITHDRAW WINNINGS          */
    /***************************************/
    function withdrawWinnings(uint256 _game) external {
        require(alreadyWithdrawn[_game][msg.sender] == false, "You already withdrew your profits from this round");
        require(payoutPerTicket[_game] != 0, "This game didn't ended yet");

        uint256 winnerTickets;
        //check if game ended with more than 0 tickets alive
        if(ticketsLeft[_game][ticketsLeft[_game].length - 1] > 0) {
            //just check tickets alive in the array
            for(uint256 i; i < getTicketsByUser[_game][msg.sender].length; i++) {
                if(getTickets[_game][getTicketsByUser[_game][msg.sender][i]] == msg.sender) winnerTickets ++;
            }
        } else {
            uint256 _ticketsByUserLength = getTicketsByUser[_game][msg.sender].length;
            //if game ended in round 1
            if(ticketsLeft[_game].length == 2) {
                winnerTickets = _ticketsByUserLength;
            } else {
                //if user has not rolled
                if(rolledNumbers[_game][msg.sender][0] == 0) {
                    uint256[4] memory boundaries = _getBoundaries(_game, 0, excludedNumbers[_game].length - 2);
                    uint256 roundCounter;
                    uint256 i;
                    while (i < _ticketsByUserLength) {
                        uint256 ticket = getTicketsByUser[_game][msg.sender][i];

                        if(ticket < ticketsLength[_game][roundCounter]) {
                            if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                                winnerTickets++;
                            }
                            i++;
                        } else if (ticket < ticketsLength[_game][roundCounter +1]){
                            roundCounter ++;
                            boundaries = _getBoundaries(_game, roundCounter, excludedNumbers[_game].length - 2);
                            if(ticket > 2 && ticket < 0 && ticket < boundaries[2] && ticket > boundaries[3]) {
                                winnerTickets++;
                            }
                            i++;
                        } else {
                            roundCounter ++;
                        }
                    }
                } else {
                    //if user has rolled
                    (uint256[] memory rolledTickets, uint256 counter) = _getRolledTickets(msg.sender, _game);
                    uint256[4] memory boundaries = _getBoundaries(_game, rolledNumbers[_game][msg.sender][1], excludedNumbers[_game].length - 2);

                    //gets the tickets that where still there last round
                    for(uint256 i; i < counter; i++) {
                        uint256 ticket = rolledTickets[i];
                        if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                            winnerTickets++;
                        }
                    }
                }
            }

        }
        require(winnerTickets != 0, "You have no winning tickets");

        alreadyWithdrawn[_game][msg.sender] = true;
        payable(msg.sender).transfer(payoutPerTicket[_game] * winnerTickets);
    }

    /***************************************/
    /*          PRIVATE FUNCTIONS          */
    /***************************************/
    function _getBoundaries(uint256 game, uint256 startingRound, uint256 finishingRound) private view returns(uint256[4] memory boundaries){
        uint256 outsideMin;
        uint256 outsideMax = MAX_INT;
        uint256 insideMin = MAX_INT;
        uint256 insideMax;

        for(uint256 i = startingRound * 2; i < finishingRound; i+=2) {
            uint256 _rng1 = excludedNumbers[game][i];
            uint256 _rng2 = excludedNumbers[game][i+1];
            uint256 _outside = _rng1 + ticketsLength[game][i] - _rng2;
            uint256 _inside = _rng2 - _rng1;
            if(_outside > _inside){
                if(_rng1 > outsideMin) outsideMin = _rng1;
                if(_rng2 < outsideMax) outsideMax = _rng2;
            } else {
                if(_rng1 < insideMin) insideMin = _rng1;
                if(_rng2 > insideMax) insideMax = _rng2;
            }
        }
        boundaries = [outsideMin, outsideMax, insideMin, insideMax];
        return boundaries;
    }

    function _getRolledTickets(address user, uint256 _game) private view returns(uint256[] memory rolledTickets, uint256 counter) {
        uint256 _ticketsByUserLength = getTicketsByUser[currentGame][user].length;

        uint256[] memory rollableTickets;
        uint256 counterI;
        uint256 counterJ;
        //if user has rolled in round 1
        if(rolledNumbers[_game][user][1] == 1) {
            rollableTickets = getTicketsByUser[_game][user];
            counterI = _ticketsByUserLength;
        } else {
            uint256[4] memory boundaries = _getBoundaries(_game, 0, (rolledNumbers[_game][user][1] * 2) - 2);
            //gets the tickets that where still alive last round
            rollableTickets = new uint256[](_ticketsByUserLength);
            for(uint256 i; i < _ticketsByUserLength; i++) {
                uint256 ticket = getTicketsByUser[_game][user][i];
                if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                    rollableTickets[counterI] = ticket;
                    counterI++;
                }
            }   
        }

        //get the 2 rolled numebers
        uint64 rng1 = rolledNumbers[_game][user][2];

        uint64 rng2 = rolledNumbers[_game][user][3];

        //checks the 2 intervals
        uint256 outside = rng1 + getTickets[_game].length-rng2;
        uint256 inside = rng2 - rng1;

        rolledTickets = new uint256[](counterI);

        if(outside > inside) {
            for(uint256 i; i < counterI; i++) {
                if(rollableTickets[i] > rng1 && rollableTickets[i] < rng2) {
                    rolledTickets [counterJ] == rollableTickets[i];
                    counterJ ++;
                }
            }
        } else {
            for(uint256 i; i < counterI; i++) {
                if(rollableTickets[i] < rng1 && rollableTickets[i] > rng2) {
                    rolledTickets [counterJ] == rollableTickets[i];
                    counterJ ++;
                }
            }
        }
        return (rolledTickets, counterJ);
    }
    
    /***************************************/
    /*         GAME SETTING (ONWER)        */
    /***************************************/
    function setTicketPrice(uint64 _ticketPrice) external onlyOwner {
        ticketPriceUpdate = _ticketPrice;
    }

    function setRoundDuration(uint256 _roundDuration) external onlyOwner {
        roundDurationUpdate = _roundDuration;
    }

    function setCooldownDuration(uint256 _cooldownDuration) external onlyOwner {
        cooldownDurationUpdate = _cooldownDuration;
    }

    function getHouseFees() external view onlyOwner returns (uint256) {
        return houseFees;
    }

    function withdrawHouseFees() external onlyOwner {
        payable(msg.sender).transfer(houseFees);
        houseFees = 0;
    }

    /***************************************/
    /*             GET RANDOM              */
    /***************************************/
    function getRandom(uint64 rng1, uint64 rng2) public pure returns (uint64, uint64) {
        return (rng1, rng2);
    }

    function getRandomNumber(uint256 max, uint256 nonce) public view returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(block.number*nonce, "random", block.timestamp*nonce)))%max);
    }


    /***************************************/
    /*            UI FUNCTIONS             */
    /***************************************/
    function ___GETTICKETSARRAY() public view returns(address[] memory) {
        return getTickets[currentGame];
    }

    function ___GETEXCLUDEDNUMBERS() public view returns(uint256[] memory) {
        return excludedNumbers[currentGame];
    }

    function ___GETROLLEDDATA() public view returns(uint64[4] memory) {
        return rolledNumbers[currentGame][msg.sender];
    }

    function ___GETMYTICKETSALIVE() public view returns (uint256[] memory) {
        uint256 count;
        uint256 [] memory _tickets = new uint256[](getTicketsByUser[currentGame][msg.sender].length);
        for(uint256 i; i < getTicketsByUser[currentGame][msg.sender].length; i++) {
            if(getTickets[currentGame][getTicketsByUser[currentGame][msg.sender][i]] != address(0)) {
                _tickets[count] = getTicketsByUser[currentGame][msg.sender][i];
                count++;
            }
        } 
        uint256 [] memory tickets = new uint256[](count);
        for(uint256 i; i<count; i++){
            tickets[i] = _tickets[i];
        }
        return tickets;
    }

    function ___GETMYROLLABLETICKETS() external view returns (uint256[] memory) {

        bool _canRoll = true;
        uint256 _ticketsByUserLength = getTicketsByUser[currentGame][msg.sender].length;
        for(uint256 i; i < getTicketsByUser[currentGame][msg.sender].length; i++) {
            if(getTickets[currentGame][getTicketsByUser[currentGame][msg.sender][i]] != address(0)) _canRoll = false;
        }

        uint256[] memory rollableTickets;
        uint256 counter;

        if(_ticketsByUserLength == 0 || rolledNumbers[currentGame][msg.sender][0] == 1 || _canRoll == false) return rollableTickets;

        else if(currentRound == 1) {
            rollableTickets = getTicketsByUser[currentGame][msg.sender];
            counter = _ticketsByUserLength;
            return rollableTickets;
        } else {
            rollableTickets = new uint256[](_ticketsByUserLength);
            uint256[4] memory boundaries = _getBoundaries(currentGame, 0, excludedNumbers[currentGame].length - 2);
            uint256 roundCounter;
            uint256 i;
            while (i < _ticketsByUserLength) {
                uint256 ticket = getTicketsByUser[currentGame][msg.sender][i];

                if(ticket < ticketsLength[currentGame][roundCounter]) {
                    if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                        rollableTickets[counter] = ticket;
                        counter++;
                    }
                    i++;
                } else if (ticket < ticketsLength[currentGame][roundCounter +1]){
                    roundCounter ++;
                    boundaries = _getBoundaries(currentGame, roundCounter, excludedNumbers[currentGame].length - 2);
                    if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                        rollableTickets[counter] = ticket;
                        counter++;
                    }
                    i++;
                } else {
                    roundCounter ++;
                }
            }
            uint256[] memory _rollableTickets = new uint256[](counter);
            for (uint256 j; j < counter; j++) {
                _rollableTickets[j] = rollableTickets[j];
            }
            return _rollableTickets;
        }

    }
    function ___GETMYWINNINGTICKETS(uint256 _game)  external view returns (uint256) {
        uint256 winnerTickets;
        //if that game was aborted
        if(ticketsLeft[_game][0] == 0) return winnerTickets;
        //check if game ended with more than 0 tickets alive
        else if(ticketsLeft[_game][ticketsLeft[_game].length - 1] > 0) {
            //just check tickets alive in the array
            for(uint256 i; i < getTicketsByUser[_game][msg.sender].length; i++) {
                if(getTickets[_game][getTicketsByUser[_game][msg.sender][i]] == msg.sender) winnerTickets ++;
            }
        } else {
            uint256 _ticketsByUserLength = getTicketsByUser[_game][msg.sender].length;
            //if game ended in round 1
            if(ticketsLeft[_game].length == 2) {
                winnerTickets = _ticketsByUserLength;
            } else {
                //if user has not rolled
                if(rolledNumbers[_game][msg.sender][0] == 0) {
                    uint256[4] memory boundaries = _getBoundaries(_game, 0, excludedNumbers[_game].length - 2);
                    uint256 roundCounter;
                    uint256 i;
                    while (i < _ticketsByUserLength) {
                        uint256 ticket = getTicketsByUser[_game][msg.sender][i];

                        if(ticket < ticketsLength[_game][roundCounter]) {
                            if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                                winnerTickets++;
                            }
                            i++;
                        } else if (ticket < ticketsLength[_game][roundCounter +1]){
                            roundCounter ++;
                            boundaries = _getBoundaries(_game, roundCounter, excludedNumbers[_game].length - 2);
                            if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                                winnerTickets++;
                            }
                            i++;
                        } else {
                            roundCounter ++;
                        }
                    }
                } else {
                    //if user has rolled
                    (uint256[] memory rolledTickets, uint256 counter) = _getRolledTickets(msg.sender, _game);
                    uint256[4] memory boundaries = _getBoundaries(_game, rolledNumbers[_game][msg.sender][1], excludedNumbers[_game].length - 2);

                    //gets the tickets that where still there last round
                    for(uint256 i; i < counter; i++) {
                        uint256 ticket = rolledTickets[i];
                        if(ticket > boundaries[0] && ticket < boundaries[1] && ticket < boundaries[2] && ticket > boundaries[3]) {
                            winnerTickets++;
                        }
                    }
                }
            }

        }

        return winnerTickets;
    }
    function ___GETTICKETSBYOWNERARRAY() public view returns(uint256[] memory) {
        return getTicketsByUser[currentGame][msg.sender];
    }

    function ___GETTICKETSPOSITION(uint256 ticket) public view returns(uint256) {
        return getTicketsPositionByUser[currentGame][msg.sender][ticket];
    }
    function ___GETJACKPOT() external view returns (uint256) {
        //74% of 96 = 71.04
        return jackpot * 74 / 100;
    }
}