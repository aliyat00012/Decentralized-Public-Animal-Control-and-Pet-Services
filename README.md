# Decentralized Public Animal Control and Pet Services

A comprehensive blockchain-based system for managing public animal control services, pet licensing, adoptions, and veterinary care coordination.

## System Overview

This system consists of five interconnected smart contracts that provide a complete solution for public animal control and pet services:

### 1. Animal Licensing Contract (\`animal-licensing.clar\`)
- **Purpose**: Tracks pet ownership and vaccination requirements
- **Features**:
    - Pet registration with owner details
    - Vaccination record management
    - License renewal tracking
    - Compliance monitoring

### 2. Stray Animal Rescue Coordination Contract (\`stray-rescue.clar\`)
- **Purpose**: Manages animal control operations and shelter placement
- **Features**:
    - Stray animal reporting system
    - Rescue operation coordination
    - Shelter capacity management
    - Animal status tracking

### 3. Adoption Process Management Contract (\`adoption-management.clar\`)
- **Purpose**: Facilitates pet adoptions and tracks animal welfare outcomes
- **Features**:
    - Adoption application processing
    - Applicant screening and approval
    - Post-adoption follow-up tracking
    - Animal welfare outcome monitoring

### 4. Veterinary Service Coordination Contract (\`veterinary-services.clar\`)
- **Purpose**: Connects low-income pet owners with affordable veterinary care
- **Features**:
    - Income verification for assistance programs
    - Veterinary service provider network
    - Appointment scheduling and tracking
    - Subsidized care program management

### 5. Animal Bite Incident Tracking Contract (\`bite-incident-tracking.clar\`)
- **Purpose**: Records and investigates animal attacks for public safety
- **Features**:
    - Incident reporting and documentation
    - Investigation workflow management
    - Animal quarantine tracking
    - Public safety alert system

## Key Benefits

- **Transparency**: All operations recorded on blockchain for public accountability
- **Efficiency**: Automated processes reduce administrative overhead
- **Accessibility**: 24/7 availability for reporting and services
- **Data Integrity**: Immutable records prevent tampering
- **Cost Reduction**: Streamlined operations reduce municipal costs

## Technical Architecture

### Data Structures
- **Maps**: Store entity relationships and status information
- **Variables**: Track system-wide statistics and configurations
- **Constants**: Define error codes and system parameters

### Access Control
- **Admin Functions**: Municipal animal control officers
- **Public Functions**: Citizens can report, apply, and access services
- **Read-Only Functions**: Transparent data access for all stakeholders

### Error Handling
- Comprehensive error codes for all failure scenarios
- Input validation and sanitization
- Proper authorization checks

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Usage Examples

#### Register a Pet
\`\`\`clarity
(contract-call? .animal-licensing register-pet
"Buddy"
"Golden Retriever"
u2
"2023-01-15"
"Rabies, DHPP")
\`\`\`

#### Report a Stray Animal
\`\`\`clarity
(contract-call? .stray-rescue report-stray
"Large brown dog, no collar"
"Main St & 5th Ave"
u1)
\`\`\`

#### Submit Adoption Application
\`\`\`clarity
(contract-call? .adoption-management submit-application
u123
"John Doe"
"123 Pet Lane"
"555-0123")
\`\`\`

## Testing

The system includes comprehensive tests using Vitest:

- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing
- Performance and gas optimization tests

Run tests with: \`npm test\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or support, please open an issue in the GitHub repository or contact the municipal animal control department.
