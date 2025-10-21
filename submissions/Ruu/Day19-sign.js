(async() => {
    const messageHash = "paste-your-hash-here";
    const accounts = await web3.eth.getAccounts();
    const organizer = accounts[0];
    const signature = await web3.eth.sign(messageHash, organizer);
    console.log("Signature:", signature);
}
)
();
