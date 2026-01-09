(async() => {
    const messageHash = "0xcf60bed6bd3bd714da2e6307764c60dfd618d1a17a4faa3954d45ebead684bac";
    const accounts = await web3.eth.getAccounts();
    const organizer = accounts[0];
    const signature = await web3.eth.personal.sign(messageHash, organizer);
    
    console.log("Signature:", signature);
})();