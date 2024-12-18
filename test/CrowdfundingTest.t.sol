// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding public crowdfunding;

    function setUp() public {
        crowdfunding = new Crowdfunding();
    }

    function testCreateCampaignSuccess() public {
        // Parâmetros da campanha
        string memory name = "Campanha Teste";
        uint256 goal = 1 ether;
        uint256 duration = 7 days;

        // Chama o método para criar a campanha
        crowdfunding.createCampaign(name, goal, duration);

        // Verifica os detalhes da campanha criada
        (
            address creator,
            string memory campaignName,
            uint256 campaignGoal,
            uint256 deadline,
            uint256 totalContributed,
            bool isWithdrawn
        ) = crowdfunding.campaigns(0);

        assertEq(creator, address(this)); // Criador é o contrato de teste
        assertEq(campaignName, name); // Nome correto
        assertEq(campaignGoal, goal); // Meta correta
        assertEq(deadline, block.timestamp + duration); // Prazo correto
        assertEq(totalContributed, 0); // Nenhuma contribuição no início
        assertEq(isWithdrawn, false); // Nenhum saque no início
    }

    function testCreateCampaignEmptyNameShouldFail() public {
        // Nome vazio deve falhar
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.NameCannotBeEmpty.selector));
        crowdfunding.createCampaign("", 1 ether, 7 days);
    }

    function testCreateCampaignGoalZeroShouldFail() public {
        // Meta de arrecadação zero deve falhar
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.GoalMustBeGreaterThanZero.selector));
        crowdfunding.createCampaign("Campanha Teste", 0, 7 days);
    }

    function testCreateCampaignDurationZeroShouldFail() public {
        // Duração zero deve falhar
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.DurationMustBeGreaterThanZero.selector));
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 0);
    }

    function testCreateMultipleCampaigns() public {
        // Cria várias campanhas
        crowdfunding.createCampaign("Campanha 1", 1 ether, 7 days);
        crowdfunding.createCampaign("Campanha 2", 2 ether, 10 days);

        // Verifica detalhes da primeira campanha
        (address creator1, string memory name1, uint256 goal1, uint256 deadline1,,) = crowdfunding.campaigns(0);
        assertEq(creator1, address(this));
        assertEq(name1, "Campanha 1");
        assertEq(goal1, 1 ether);
        assertEq(deadline1, block.timestamp + 7 days);

        // Verifica detalhes da segunda campanha
        (address creator2, string memory name2, uint256 goal2, uint256 deadline2,,) = crowdfunding.campaigns(1);
        assertEq(creator2, address(this));
        assertEq(name2, "Campanha 2");
        assertEq(goal2, 2 ether);
        assertEq(deadline2, block.timestamp + 10 days);
    }

    function testContributeSuccess() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Atribui fundos à conta address(1)
        vm.deal(address(1), 10 ether); // Simula 10 ETH na conta address(1)

        // Contribuir com 0.5 ether
        vm.prank(address(1)); // Simula outra conta
        crowdfunding.contribute{value: 0.5 ether}(0);

        // Verifica os detalhes da campanha
        (,,,, uint256 totalContributed,) = crowdfunding.campaigns(0);
        assertEq(totalContributed, 0.5 ether); // Total contribuído atualizado

        // Verifica a contribuição individual
        uint256 contribution = crowdfunding.getContribution(0, address(1));
        assertEq(contribution, 0.5 ether);
    }

    function testContributeAfterDeadlineShouldFail() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Atribui fundos à conta address(1)
        vm.deal(address(1), 10 ether); // Simula 10 ETH na conta address(1)

        // Avança o tempo para além do prazo
        vm.warp(block.timestamp + 8 days);

        // Tentar contribuir deve falhar
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.CampaignExpired.selector));
        crowdfunding.contribute{value: 1 ether}(0);
    }

    function testContributeZeroValueShouldFail() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Tentar contribuir com valor zero deve falhar
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.ContributionMustBeGreaterThanZero.selector));
        crowdfunding.contribute{value: 0}(0);
    }

    function testWithdrawFundsSuccess() public {
        // Endereço do criador da campanha
        address campaignCreator = address(200);

        // Simula o criador da campanha como uma conta simples
        vm.etch(campaignCreator, "");

        // Cria uma campanha
        vm.prank(campaignCreator);
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Endereço do contribuinte
        address contributor = address(100);

        // Atribui saldo ao contribuinte
        vm.deal(contributor, 10 ether);

        // Contribuição
        vm.prank(contributor);
        crowdfunding.contribute{value: 1 ether}(0);

        // Avança o tempo para além do prazo
        vm.warp(block.timestamp + 8 days);

        // Solicita o saque
        uint256 balanceBefore = campaignCreator.balance;
        vm.prank(campaignCreator);
        crowdfunding.withdrawFunds(0);
        uint256 balanceAfter = campaignCreator.balance;

        // Verifica se os fundos foram sacados
        assertEq(balanceAfter - balanceBefore, 1 ether);
    }

    function testWithdrawFundsBeforeDeadlineShouldFail() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Tentar sacar antes do prazo expirar deve falhar
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.CampaignOngoing.selector));
        crowdfunding.withdrawFunds(0);
    }

    function testWithdrawFundsWithoutReachingGoalShouldFail() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Atribui fundos à conta address(1)
        vm.deal(address(1), 10 ether); // Simula 10 ETH na conta address(1)

        // Contribuir com menos do que a meta
        vm.prank(address(1));
        crowdfunding.contribute{value: 0.5 ether}(0);

        // Avança o tempo para além do prazo
        vm.warp(block.timestamp + 8 days);

        // Tentar sacar deve falhar
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.GoalNotMet.selector));
        crowdfunding.withdrawFunds(0);
    }

    function testRefundSuccess() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Use um endereço arbitrário não reservado
        address contributor = address(100);

        // Atribui fundos ao endereço contributor
        vm.deal(contributor, 10 ether); // Simula 10 ETH na conta contributor

        // Transforma contributor em uma conta simples que aceita ether
        vm.etch(contributor, "");

        // Contribuir com 0.5 ether
        vm.prank(contributor);
        crowdfunding.contribute{value: 0.5 ether}(0);

        // Avança o tempo para além do prazo
        vm.warp(block.timestamp + 8 days);

        // Solicitar reembolso
        uint256 balanceBefore = contributor.balance;
        vm.prank(contributor);
        crowdfunding.refund(0);
        uint256 balanceAfter = contributor.balance;

        // Verifica se o reembolso foi processado
        assertEq(balanceAfter - balanceBefore, 0.5 ether);
    }

    function testRefundAfterGoalReachedShouldFail() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Atribui fundos à conta address(1)
        vm.deal(address(1), 10 ether); // Simula 10 ETH na conta address(1)

        // Contribuir com 1 ether
        vm.prank(address(1));
        crowdfunding.contribute{value: 1 ether}(0);

        // Avança o tempo para além do prazo
        vm.warp(block.timestamp + 8 days);

        // Tentar reembolso deve falhar
        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.GoalNotMet.selector));
        crowdfunding.refund(0);
    }

    function testRefundWithoutContributionShouldFail() public {
        // Cria uma campanha
        crowdfunding.createCampaign("Campanha Teste", 1 ether, 7 days);

        // Avança o tempo para além do prazo
        vm.warp(block.timestamp + 8 days);

        // Tentar reembolso sem ter contribuído deve falhar
        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.NoContributionToRefund.selector));
        crowdfunding.refund(0);
    }
}
