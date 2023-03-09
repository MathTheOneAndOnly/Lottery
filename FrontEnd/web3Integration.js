const ABI = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[],"name":"MAX_INT","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"game","type":"uint256"},{"internalType":"uint256","name":"startingRound","type":"uint256"},{"internalType":"uint256","name":"finishingRound","type":"uint256"}],"name":"_getBoundaries","outputs":[{"internalType":"uint256[4]","name":"boundaries","type":"uint256[4]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"}],"name":"alreadyWithdrawn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"buyTickets","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"buyTickets2","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"cooldownDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"cooldownDurationUpdate","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"currentGame","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"currentRound","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"excludedNumbers","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"getTickets","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"getTicketsByUser","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"payoutPerTicket","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"returnnn","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"rolledNumbers","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"roundDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"roundDurationUpdate","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"startedAt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ticketPrice","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ticketPriceUpdate","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"ticketsLeft","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"}]
const contractAddress = '0x2b6652a9ccA275ceDDf86f27275221b9e898db75'
const dataseed = new Web3(new Web3.providers.HttpProvider('https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161'))

let contract;
let myaddress;
let price;
let myTickets
async function approveMethamask() {
    web3 = new Web3(window.ethereum)
    contract = new web3.eth.Contract(ABI, contractAddress)
    myaddress = await window.ethereum.enable()
    if(!myaddress) {
        approveMethamask()
        return
    }
    myaddress = myaddress[0]
    enabled = true
    return
}
approveMethamask()

async function roll() {
    const gasPrice = await web3.eth.getGasPrice()
    let args = {
        from:myaddress,
        gasPrice: gasPrice,
        value: 0
    }
    await contract.methods.roll().send(args)
}

async function finishRound() {
    const gasPrice = await web3.eth.getGasPrice()
    let args = {
        from:myaddress,
        gasPrice: gasPrice,
        value: 0
    }
    await contract.methods.finishRound().send(args)
}

async function buyTickets() {
    const gasPrice = await web3.eth.getGasPrice()
    const amount = document.getElementById('amount').value
    let args = {
        from:myaddress,
        gasPrice: gasPrice,
        value: amount*price
    }

    await contract.methods.buyTickets(amount).send(args)
}

async function ClaimRewards(game) {
    const gasPrice = await web3.eth.getGasPrice()
    let args = {
        from: myaddress,
        gasPrice: gasPrice,
        value: 0
    }

    await contract.methods.withdrawWinnings(game).send(args)
}

async function getCurrentGame() {
    currentGame = await contract.methods.currentGame().call()
    updateHtml('currentGame', currentGame)
}

async function getCurrentRound() {
    currentRound = await contract.methods.currentRound().call()
    updateHtml('currentRound', currentRound)
}

async function getExcludedNumbers() {
    excludedNumbers = await contract.methods.___GETEXCLUDEDNUMBERS().call()
    if(excludedNumbers.length > 0){
        let html = '';
        for(let i = 0; i < excludedNumbers.length; i+=2) {
            html += '<div> Round '+[i/2]+': '
            html += '<span class="excluded-numbers">'+excludedNumbers[i]+' and </span>'
            html += '<span class="excluded-numbers">'+excludedNumbers[i+1]+'</span>'
            html += '</div>'
        }
        updateHtml('excludedNumbers', html)
    }
    else {
        html = 'No numbers drawn yet'
        updateHtml('excludedNumbers', html)
    }
    
}

async function getEthBalance() {
    ethBalance = await web3.eth.getBalance(myaddress)
    ethBalance = Web3.utils.fromWei(ethBalance, 'ether') + ' ETH'
    updateHtml('ethBalance', ethBalance)
}
async function getMyTickets() {
    myTickets = await contract.methods.___GETTICKETSBYOWNERARRAY().call({from:myaddress})
    if(myTickets.length > 0){
        myTickets = myTickets.slice(0).sort((a, b) => a - b)
        updateHtml('myTickets', myTickets)
    }
    else updateHtml('myTickets', 'No tickets')
}


async function getMyTicketsAlive() {
    myTicketsAlive = await contract.methods.___GETMYTICKETSALIVE().call({from:myaddress})

    if(myTicketsAlive.length > 0) {
        myTicketsAlive = myTicketsAlive.slice(0).sort((a, b) => a - b)
        updateHtml('myTicketsAlive', myTicketsAlive)
    }

    else updateHtml('myTicketsAlive', 'No tickets')
}

async function getMyRolledNumbers() {
    myRoll = await contract.methods.___GETMYTICKETSALIVE().call({from:myaddress})
    if(myRoll[0] == 1) {
        updateHtml('rolledNumbers', 'Round rolled: ' + myRoll[1] +'<br>Drawn Numbers: ' + myRoll[2] +' and '+ myRoll[3])
    }
    else updateHtml('rolledNumbers', 'You didn\' rolled yet')
}

async function getMyRollableTickets() {
    myRollableTickets = await contract.methods.___GETMYROLLABLETICKETS().call({from:myaddress})
    if(myRollableTickets.length > 0) {
        myRollableTickets = myRollableTickets.slice(0).sort((a, b) => a - b)
        updateHtml('myRollableTickets', myRollableTickets)
        document.getElementById("roll").disabled = false;
    }
    else{
        updateHtml('myRollableTickets', 'You can only roll if all your tickets have been eliminated')
        document.getElementById("roll").disabled = true;
    }
}
async function getWinnings() {
    const currentGame = await contract.methods.currentGame().call()

    let html = ''
    for(let i = 0; i < currentGame; i++) {
        const winningsPerTicket = await contract.methods.payoutPerTicket(i).call({from:myaddress})
        const winningTickets = await contract.methods.___GETMYWINNINGTICKETS(i).call({from:myaddress})
        const alreadyWithdrawn = await contract.methods.alreadyWithdrawn(i, myaddress).call()
        if(winningTickets == 0) {
            html += `<div class="winnings">
            <div class="caption">Game: <div class="no-caption"><span id="ticketPrice">${i}</span></div></div>
            <div class="caption">Winnings per ticket: <div class="no-caption"><span>${Web3.utils.fromWei(String(winningsPerTicket, 'ether'))} ETH</span></div></div>
            <div class="caption">Winning tickets: <div class="no-caption"><span>${winningTickets}</span></div></div>
            <div class="caption">Claim: <div class="no-caption"></div><input disabled value=0 ETH"></input> <button disabled onclick="ClaimRewards(${i})">Nothing to withdraw</button></div>
            </div>`
        }
        else if(alreadyWithdrawn) {
            html += `<div class="winnings">
            <div class="caption">Game: <div class="no-caption"><span id="ticketPrice">${i}</span></div></div>
            <div class="caption">Winnings per ticket: <div class="no-caption"><span>${Web3.utils.fromWei(String(winningsPerTicket, 'ether'))} ETH</span></div></div>
            <div class="caption">Winning tickets: <div class="no-caption"><span>${winningTickets}</span></div></div>
            <div class="caption">Claim: <div class="no-caption"></div><input disabled value="${Web3.utils.fromWei(String(winningTickets*winningsPerTicket), 'ether')} ETH"></input> <button disabled onclick="ClaimRewards(${i})">You already withdrew your rewards</button></div>
            </div>`
        } else {
            html += `<div class="winnings">
            <div class="caption">Game: <div class="no-caption"><span id="ticketPrice">${i}</span></div></div>
            <div class="caption">Winnings per ticket: <div class="no-caption"><span>${Web3.utils.fromWei(String(winningsPerTicket, 'ether'))} ETH</span></div></div>
            <div class="caption">Winning tickets: <div class="no-caption"><span>${winningTickets}</span></div></div>
            <div class="caption">Claim: <div class="no-caption"></div><input disabled value="${Web3.utils.fromWei(String(winningTickets*winningsPerTicket), 'ether')} ETH"></input> <button onclick="ClaimRewards(${i})">Claim</button></div>
            </div>`
        }

    }
    updateHtml('winnings-container', html)

}
async function getAllTickets() {
    let _allTickets = '';
    const allTickets = await contract.methods.___GETTICKETSARRAY().call()
    if(allTickets.length == 0) {
        updateHtml('allTickets', 'No tickets bought yet')
    }
    else {
        allTickets.forEach((ticket, i)=>{
            if(myTickets.includes(i.toString())) {
                if(ticket == '0x0000000000000000000000000000000000000000') _allTickets +=  '<div class="ticket minebutdead">'+i+'</div>'
                else _allTickets += '<div class="ticket mine">'+i+'</div>'
            }  
            else if(ticket == '0x0000000000000000000000000000000000000000') _allTickets += '<div class="ticket dead">'+i+'</div>'
            else  _allTickets += '<div class="ticket others">'+i+'</div>'
        })
        updateHtml('allTickets', _allTickets)
    }
}

async function getTicketPrice() {
    price = await contract.methods.ticketPrice().call()
    if(price) updateHtml('ticketPrice', Web3.utils.fromWei(price, 'ether') + ' ETH')
}

function updateHtml(id, value) {
    document.getElementById(id).innerHTML = value
}

document.getElementById('amount').addEventListener("keyup", (event) => {
    document.getElementById('totalCost').value = Web3.utils.fromWei(String(document.getElementById('amount').value * price), 'ether') + ' ETH'
  });

async function startTimer() {
    let startedAt = await contract.methods.startedAt(currentGame, currentRound).call()
    let duration = await contract.methods.roundDuration().call()
    let countDown = (Number(startedAt) +Number( duration)) -  Math.floor(Date.now()/1000)
    let display = document.getElementById('countDown')
    let timer = countDown, minutes, seconds;
    let countDownTimer = setInterval(function () {

        countDown --
        if (timer < 0) {
            document.getElementById("finishRound").disabled = false;
            clearInterval(countDownTimer)
            startTimer()
        }
        else {
            minutes = parseInt(timer / 60, 10);
            seconds = parseInt(timer % 60, 10);
    
            minutes = minutes < 10 ? "0" + minutes : minutes;
            seconds = seconds < 10 ? "0" + seconds : seconds;
    
            display.textContent = minutes + ":" + seconds;
            timer = countDown;
            document.getElementById("finishRound").disabled = true;
        }
    }, 1000);
}
window.onload = function() {
    setTimeout(() => {
        startTimer()
    }, 3000)
}
setInterval(()=>{
    getMyTickets()
    getMyRollableTickets()
    getEthBalance()
    getExcludedNumbers()
    getMyTicketsAlive()
    getTicketPrice()
    getAllTickets()
    getCurrentGame()
    getCurrentRound()
    getMyRolledNumbers()
    approveMethamask() 
    getWinnings()
},2000)