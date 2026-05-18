# Day 18: Oracles & Crop Insurance

## Overview
For Day 18 of the 30 Days of Solidity challenge, we are focusing on Oracle Integration. We will build a Crop Insurance smart contract that uses an external Oracle to determine if a payout should be made based on rainfall data.

## Requirements
- **Oracle Integration**: Connect to an external data source to fetch weather/rainfall data.
- **AggregatorV3Interface**: Use Chainlink's AggregatorV3Interface to fetch data securely and reliably.
- **Rainfall Payout Logic**: Implement the business logic to trigger a payout to insured farmers if the reported rainfall meets the insurance conditions.

## Contracts
- `MockWeatherOracle.sol`: Acts as the "Sensor" to provide mock rainfall data for testing.
- `CropInsurance.sol`: Contains the "Business Logic" for managing policies, checking the oracle, and processing payouts.
