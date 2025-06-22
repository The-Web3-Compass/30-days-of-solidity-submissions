
(async () => {
  const messageHash = "0x72ee0b26b6cea23eb17202613d104407436153cd05ed3c6fd0276a573db2426e";
  const accounts = await web3.eth.getAccounts();
  const organizer = accounts[0]; // first account in Remix
  const signature = await web3.eth.sign(messageHash, organizer);
  console.log("Signature:", signature);
})();
