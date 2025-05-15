(async()=>{
   const messageHash = "paste your hash here"
   const accounts = await web3.eth.getAccounts()
   const organizer = accounts[0];

   const sign = await web3.eth.sign(messageHash, organizer)
   console.log("signature", sign)
})()