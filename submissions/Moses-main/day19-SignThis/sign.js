(async () => {
  const messageHash =
    "0xfbb33c2da4a9b04576802abfb27083284dd68d83f8bec3eead2b138af407f82c";
  const accounts = await web3.eth.getAccounts();
  const organizer = accounts[0]; // first account in Remix
  const signature = await web3.eth.sign(messageHash, organizer);
  console.log("Signature:", signature);
})();
