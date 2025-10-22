function saveAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory) {
    name=_name;
    bio=_bio;
    return (name, bio);
}