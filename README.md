# SkillSphere

A blockchain-based platform for tracking professional certifications and skills development on the Stacks network. This contract allows organizations to issue verifiable certifications and users to maintain an immutable record of their professional achievements.

## Features
- Issue new certifications
- Verify certification authenticity
- Track certification expiration
- Add endorsements to certifications
- Query certification history
- Transfer certifications between users
- Issuer staking mechanism for enhanced trust

## Usage
The contract provides functions for:
- Organizations to stake STX and become authorized issuers
- Organizations to issue certifications
- Users to claim and manage their certifications
- Users to transfer their certifications
- Anyone to verify certification validity
- Adding skill endorsements
- Tracking certification expiration dates

## Issuer Staking
To ensure trust and accountability, issuers must stake a minimum amount of STX tokens to be authorized to issue certifications. The staking mechanism includes:
- Minimum stake requirement
- Ability to increase stake
- Controlled unstaking process
- Automatic status updates based on stake amount

## Certification Transfer
Certifications can optionally be made transferable at the time of issuance. This enables:
- Transfer of certifications between users
- Maintaining certification history
- Preserving endorsements during transfers
