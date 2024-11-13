import { ethers } from "hardhat";
import { expect } from "chai";
import { SportsAcademyProgram } from "../typechain-types/SportsAcademyProgram";

describe("SportsAcademyProgram", function () {
    let sportsAcademy: SportsAcademyProgram;
    let owner: any, player: any, nonOwner: any;
    let agent: any, club: any;
    const birthCertificateNumber = ethers.utils.formatBytes32String("12345");
    const dateOfBirth = ethers.utils.formatBytes32String("2000-01-01");
    const businessName = ethers.utils.formatBytes32String("SportsCo");
    const businessIdentificationNumber = ethers.utils.formatBytes32String("54321");
    const referenceNumber = ethers.utils.formatBytes32String("ref-0001");
    const purchaseAmount = ethers.utils.parseEther("1");

    beforeEach(async () => {
        [owner, player, nonOwner, agent, club] = await ethers.getSigners();

        // Deploy the contract
        const SportsAcademyProgramFactory = await ethers.getContractFactory("SportsAcademyProgram");
        sportsAcademy = await SportsAcademyProgramFactory.deploy();
        await sportsAcademy.deployed();
    });

    it("should register a new player", async () => {
        await sportsAcademy.connect(player).registerNewPlayer(birthCertificateNumber, dateOfBirth);
        const playerData = await sportsAcademy.sportsAcademyProgram().players(player.address);

        expect(playerData.registered).to.be.true;
        expect(playerData.birthCertificateNumber).to.equal(birthCertificateNumber);
        expect(playerData.dateOfBirth).to.equal(dateOfBirth);
    });

    it("should register a new company", async () => {
        await sportsAcademy.registerNewCompany(businessName, businessIdentificationNumber);
        const companyData = await sportsAcademy.sportsAcademyProgram().companyData();

        expect(companyData.registered).to.be.true;
        expect(companyData.businessName).to.equal(businessName);
        expect(companyData.businessIdentificationNumber).to.equal(businessIdentificationNumber);
    });

    it("should allow buying a player", async () => {
        await sportsAcademy.connect(player).registerNewPlayer(birthCertificateNumber, dateOfBirth);
        const agentData = { businessName, businessIdentificationNumber, country: ethers.utils.formatBytes32String("USA") };
        const clubData = { businessName, businessIdentificationNumber, country: ethers.utils.formatBytes32String("UK") };

        await sportsAcademy.buyNewPlayer(referenceNumber, player.address, agentData, clubData, purchaseAmount);
        const playerPurchaseData = await sportsAcademy.sportsAcademyProgram().playerPurchases(referenceNumber);

        expect(playerPurchaseData.initialised).to.be.true;
        expect(playerPurchaseData.purchaseAmount).to.equal(purchaseAmount);
    });

    it("should allow deposit for player purchase", async () => {
        await sportsAcademy.connect(player).registerNewPlayer(birthCertificateNumber, dateOfBirth);

        const agentData = { businessName, businessIdentificationNumber, country: ethers.utils.formatBytes32String("USA") };
        const clubData = { businessName, businessIdentificationNumber, country: ethers.utils.formatBytes32String("UK") };
        await sportsAcademy.buyNewPlayer(referenceNumber, player.address, agentData, clubData, purchaseAmount);

        await sportsAcademy.connect(owner).depositFunds(player.address, referenceNumber, { value: purchaseAmount });

        const vaultBalance = await sportsAcademy.getVaultBalance();
        expect(vaultBalance).to.equal(purchaseAmount);

        const playerPurchaseData = await sportsAcademy.sportsAcademyProgram().playerPurchases(referenceNumber);
        expect(playerPurchaseData.approved).to.be.true;

        const playerData = await sportsAcademy.sportsAcademyProgram().players(player.address);
        expect(playerData.sold).to.be.true;
    });

    it("should only allow admin to withdraw from vault", async () => {
        await sportsAcademy.depositFunds(player.address, referenceNumber, { value: purchaseAmount });

        await expect(sportsAcademy.connect(nonOwner).withdraw(purchaseAmount)).to.be.revertedWith("Only the admin can call this function");

        await sportsAcademy.connect(owner).withdraw(purchaseAmount);
        const vaultBalance = await sportsAcademy.getVaultBalance();
        expect(vaultBalance).to.equal(0);
    });
});
