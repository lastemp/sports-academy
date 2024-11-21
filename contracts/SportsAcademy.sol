// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
	
contract Player {
    struct PlayerData {
      bytes birthCertificateNumber;
	  bytes dateOfBirth;
      bool registered;
      bool sold;
      address owner;
    }

    PlayerData playerData;

    function registerPlayer(bytes memory birthCertificateNumber_, bytes memory dateOfBirth_) internal returns (PlayerData memory) {
        require(birthCertificateNumber_.length > 0, "Birth Certificate Number has invalid value.");
		require(dateOfBirth_.length > 0, "Date of birth has invalid value.");
        playerData.birthCertificateNumber = birthCertificateNumber_;
        playerData.dateOfBirth = dateOfBirth_;
        playerData.registered = true;
        playerData.owner = msg.sender;

        return playerData;
    }
}

contract Company {
struct CompanyData {
      bytes businessName;
	  bytes businessIdentificationNumber;
      bool registered;
      bool approved;
      address owner;
	  address admin;
    }

    CompanyData companyData;
	
	// Constructor code is only run when the contract
    // is created
    constructor() {
        companyData.admin = msg.sender;
    }

    function registerCompany(bytes memory businessName_, bytes memory businessIdentificationNumber_) internal returns (CompanyData memory) {
        require(businessName_.length > 0, "Business Name has invalid value.");
		require(businessIdentificationNumber_.length > 0, "Business Identification Number has invalid value.");
        companyData.businessName = businessName_;
		companyData.businessIdentificationNumber = businessIdentificationNumber_;
        companyData.registered = true;
        companyData.owner = msg.sender;

        return companyData;
    }
	
}

contract PlayerPurchase {
    struct FootballAgentData {
      bytes businessName;
	  bytes businessIdentificationNumber;
	  bytes country;
    }
struct FootballClubData {
      bytes businessName;
	  bytes businessIdentificationNumber;
	  bytes country;
    }
struct PlayerPurchaseData {
      bytes referenceNumber;
      address player;
	  FootballAgentData agent;
	  FootballClubData club;
	  uint256 purchaseAmount;
	  bool initialised;
      bool approved;
	  address admin;
    }	

    PlayerPurchaseData playerPurchaseData;
	
	// Constructor code is only run when the contract
    // is created
    constructor() {
        playerPurchaseData.admin = msg.sender;
    }

    function buyPlayer(bytes memory referenceNumber_, address player_, FootballAgentData memory agent_, FootballClubData memory club_, uint256 purchaseAmount_) internal returns (PlayerPurchaseData memory) {
	    require(referenceNumber_.length > 0, "Reference Number has invalid value.");
		require(purchaseAmount_ > 0, "Purchase amount must be greater than zero");
        playerPurchaseData.referenceNumber = referenceNumber_;
        playerPurchaseData.player = player_;
        playerPurchaseData.agent = agent_;
		playerPurchaseData.club = club_;
		playerPurchaseData.initialised = true;
        playerPurchaseData.purchaseAmount = purchaseAmount_;

        return playerPurchaseData;
    }
}

contract Vault {
    // Mapping to store each Policy holder's deposited balance
    mapping(address => uint256) public balances;

    // Address of the contract owner (admin)
    address public admin;

    // Event to log deposits
    event Deposit(address indexed member, uint256 amount);

    // Event to log withdrawals
    event Withdraw(address indexed admin, uint256 amount);

    // Constructor to set the contract admin
    constructor() {
        admin = msg.sender;
    }

    // Modifier to restrict access to admin-only functions
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    // Function for individuals to deposit funds into the vault
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        // Update the sender's balance
        balances[msg.sender] += msg.value;

        // Emit deposit event
        emit Deposit(msg.sender, msg.value);
    }

    // Function to check the vault's total balance, restricted to the admin only
    function getVaultBalance() external onlyAdmin view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw funds, restricted to the admin only
    function withdraw(uint256 amount_) external onlyAdmin {
        require(amount_ > 0, "Withdraw amount must be greater than zero");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        require(balance > amount_, "Insufficient funds");

        // Transfer the withdrawal amount to the admin
        payable(admin).transfer(amount_);

        // Emit withdraw event
        emit Withdraw(admin, amount_);
    }

    // Function to check an individual member's balance
    function getMemberBalance(address _member) external view returns (uint256) {
        return balances[_member];
    }
}

contract SportsAcademyProgram is Player, Company, PlayerPurchase, Vault {
    struct SportsAcademyProgramData {
      mapping(address => PlayerData) players;
	  CompanyData companyData;
	  mapping(bytes => PlayerPurchaseData) playerPurchases;
      uint256 totalPurchaseAmount;
      uint16 totalPlayersSold;
      address admin;
    }

    SportsAcademyProgramData sportsAcademyProgram;

    // Constructor code is only run when the contract
    // is created
    constructor() {
        sportsAcademyProgram.admin = msg.sender;
    }

    function registerNewPlayer(bytes memory birthCertificateNumber_, bytes memory dateOfBirth_) external {
        require(birthCertificateNumber_.length > 0, "Birth Certificate Number has invalid value.");
		require(dateOfBirth_.length > 0, "Date of birth has invalid value.");

        // Check if player is already registered
        PlayerData memory playerData = sportsAcademyProgram.players[msg.sender];
        require(!playerData.registered, "Player is already registered");

        // call registerPlayer in contract Player
        PlayerData memory playerData_ = registerPlayer(birthCertificateNumber_, dateOfBirth_);
        sportsAcademyProgram.players[msg.sender] = playerData_;
    }
	
	function registerNewCompany(bytes memory businessName_, bytes memory businessIdentificationNumber_) external {
        require(businessName_.length > 0, "Business Name has invalid value.");
		require(businessIdentificationNumber_.length > 0, "Business Identification Number has invalid value.");

        // Check if company is already registered
        CompanyData memory companyData = sportsAcademyProgram.companyData;
		require(!companyData.registered, "Company is already registered");

        // call registerCompany in contract Company
		sportsAcademyProgram.companyData = registerCompany(businessName_, businessIdentificationNumber_);
    }

	function buyNewPlayer(bytes memory referenceNumber_, address player_, FootballAgentData memory agent_, FootballClubData memory club_, uint256 purchaseAmount_) external {
        require(referenceNumber_.length > 0, "Reference Number has invalid value.");
		require(purchaseAmount_ > 0, "Purchase amount must be greater than zero");

        // Check if player purchase was already completed
        PlayerPurchaseData memory playerPurchaseData = sportsAcademyProgram.playerPurchases[referenceNumber_];
        require(!playerPurchaseData.initialised, "Player purchase was already completed");

        // call buyPlayer in contract PlayerPurchase
        PlayerPurchaseData memory playerPurchaseData_ = buyPlayer(referenceNumber_, player_, agent_, club_, purchaseAmount_);
        sportsAcademyProgram.playerPurchases[referenceNumber_] = playerPurchaseData_;
    }
	
	function depositFunds(address player_, bytes memory referenceNumber_) external payable {
        require(referenceNumber_.length > 0, "Reference Number has invalid value.");
        require(msg.value > 0, "Deposit amount must be greater than zero");

		PlayerData memory playerData = sportsAcademyProgram.players[player_];

        require(playerData.registered, "Player is not registered");
		require(!playerData.sold, "Player is already sold");

		PlayerPurchaseData memory playerPurchaseData = sportsAcademyProgram.playerPurchases[referenceNumber_];

        require(playerPurchaseData.initialised, "Player purchase is not registered");
		require(msg.value == playerPurchaseData.purchaseAmount, "Deposit amount must be equal to player purchase amount");
		
        deposit();
		playerPurchaseData.approved = true;
		playerData.sold = true;
		sportsAcademyProgram.totalPlayersSold += 1;
		sportsAcademyProgram.totalPurchaseAmount += msg.value;
        
    }
	
	function getPlayerData(address player_) external view returns (PlayerData memory) {
        return sportsAcademyProgram.players[player_];
    }
	
	function getCompanyData() external view returns (CompanyData memory) {
        return sportsAcademyProgram.companyData;
    }
	
	function getPlayerPurchaseData(bytes memory referenceNumber_) external view returns (PlayerPurchaseData memory) {
        return sportsAcademyProgram.playerPurchases[referenceNumber_];
    }
	
}