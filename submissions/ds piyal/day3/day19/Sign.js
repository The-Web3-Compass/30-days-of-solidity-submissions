(async() => {
    const messageHash = "0x3afaef8f78aa8234fa71d758c56786e18edbd63e7b1678cf00213ddc153d3f8d";
    const accounts = await web3.eth.getAccounts();
    const organizer = accounts[0];
    const signature = await web3.eth.personal.sign(messageHash, organizer);
    
    console.log("Signature:", signature);
})();