## Day 2 Submission: SaveMyName Contract
   
   ### 📝 Description
   A simple profile storage contract demonstrating string and bool state variables, along with data storage and retrieval on the blockchain.
   
   ### ✨ Features
   - ✅ Store user name and bio (string types)
   - ✅ Track profile status (bool type)
   - ✅ Validate name cannot be empty
   - ✅ Update existing profile
   - ✅ Delete profile functionality
   - ✅ Retrieve stored profile data
   - ✅ Events for state changes
   - ✅ Custom errors for gas efficiency
   - ✅ Complete NatSpec documentation
   
   ### 🎯 Concepts Mastered
   - String state variables
   - Bool state variables
   - Storage and retrieval of data
   - String validation using `bytes().length`
   - Using `delete` keyword
   - `calldata` for function parameters
   - Event emission
   
   ### 📊 State Variables
   - `s_name` (string public): User's name
   - `s_bio` (string public): User's bio
   - `s_hasProfile` (bool public): Profile existence indicator
   
   ### 🔧 Functions
   - `saveProfile(string, string)`: Save or update profile
   - `deleteProfile()`: Delete the stored profile
   - `getProfile()`: Retrieve profile information
   
   ### 📚 Progression from Day 1
   - Day 1: Basic uint256 counter
   - Day 2: String and bool storage (data management)
   
   ### 👤 Author
   Carlos Israel Jimenez