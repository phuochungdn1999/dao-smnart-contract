// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CleAthDAOUpgradeable is
    ERC721Upgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Proposal {
        string name;
        string description;
        uint256 createdAt;
        uint256 endAt;
        uint256 numberOfVoters;
        uint256 acceptedVotes;
        bool isClosedByAdmin;
        address createdBy;
    }

    struct ProposalInfo {
        string name;
        string description;
        uint256 proposalId;
        uint256 createdAt;
        uint256 endAt;
        uint256 numberOfVoters;
        uint256 acceptedVotes;
        bool isEnded;
        bool isAccepted;
        bool isClosedByAdmin;
        address createdBy;
    }

    uint256 public proposalId;
    uint256 public MAX_USERS_APPROVE;

    address[] public pendingMembersArr;

    mapping(uint256 => Proposal) private listProposals;
    mapping(address => bool) public listMembers;
    mapping(address => bool) public listAdmins;

    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event CreateProposalEvent(
        string name,
        string description,
        uint256 createdAt,
        uint256 endAt,
        address createdBy
    );

    event VoteEvent(uint256 proposalId, address voter, bool accept);

    event CloseProposalEvent(uint256 proposalId, address admin);

    event ApproveMembersEvent(address admin, address[] members);

    event JoinDAOEvent(address user);

    function initialize() public virtual initializer {
        __DAO_init();
    }

    function __DAO_init() internal initializer {
        __Ownable_init();
        MAX_USERS_APPROVE = 500;
    }

    modifier onlyMembers() {
        require(
            listMembers[_msgSender()] ||
                listAdmins[_msgSender()] ||
                _msgSender() == owner(),
            "Unauthorized"
        );
        _;
    }

    modifier onlyAdminOrOwner() {
        require(
            listAdmins[_msgSender()] || _msgSender() == owner(),
            "Unauthorized"
        );
        _;
    }

    function getProposalInfo(uint256 _proposalId)
        public
        view
        returns (ProposalInfo memory)
    {
        bool _isEnded = false;
        bool _isAccepted = false;
        Proposal memory proposal = listProposals[_proposalId];
        require(_proposalId < proposalId, "Not exist");
        if (proposal.endAt < block.timestamp || proposal.isClosedByAdmin) {
            _isEnded = true;
            if (
                proposal.acceptedVotes >
                (proposal.numberOfVoters - proposal.acceptedVotes)
            ) {
                _isAccepted = true;
            }
        }
        return
            ProposalInfo({
                name: proposal.name,
                description: proposal.description,
                proposalId: _proposalId,
                createdAt: proposal.createdAt,
                endAt: proposal.endAt,
                numberOfVoters: proposal.numberOfVoters,
                acceptedVotes: proposal.acceptedVotes,
                isEnded: _isEnded,
                isAccepted: _isAccepted,
                isClosedByAdmin: proposal.isClosedByAdmin,
                createdBy: proposal.createdBy
            });
    }

    function getPendingAddressArr() public view returns (address[] memory) {
        return pendingMembersArr;
    }

    function admin(address _addr) public view returns (bool) {
        return listAdmins[_addr] || _addr == owner();
    }

    function createProposal(
        string memory _name,
        string memory _description,
        uint256 _endAt
    ) external onlyMembers {
        require(_endAt > block.timestamp, "Invalid time");
        listProposals[proposalId] = Proposal({
            name: _name,
            description: _description,
            createdAt: block.timestamp,
            endAt: _endAt,
            numberOfVoters: 0,
            acceptedVotes: 0,
            isClosedByAdmin: false,
            createdBy: _msgSender()
        });
        _mint(_msgSender(), proposalId);
        proposalId++;

        emit CreateProposalEvent(
            _name,
            _description,
            block.timestamp,
            _endAt,
            _msgSender()
        );
    }

    function vote(uint256 _proposalId, bool _accept) external onlyMembers {
        Proposal storage proposal = listProposals[_proposalId];
        require(_proposalId < proposalId, "Not exist");
        require(proposal.endAt > block.timestamp, "Ended");
        require(!proposal.isClosedByAdmin, "Admin closed");
        require(!hasVoted[_proposalId][_msgSender()], "Voted");

        hasVoted[_proposalId][_msgSender()] = true;
        proposal.numberOfVoters += 1;

        if (_accept) {
            proposal.acceptedVotes += 1;
        }

        emit VoteEvent(_proposalId, _msgSender(), _accept);
    }

    function closeProposal(uint256 _proposalId) external onlyAdminOrOwner {
        Proposal storage proposal = listProposals[_proposalId];
        require(_proposalId < proposalId, "Not exist");
        require(!(proposal.endAt < block.timestamp), "Ended");
        require(!proposal.isClosedByAdmin, "Admin closed");

        proposal.isClosedByAdmin = true;

        emit CloseProposalEvent(_proposalId, _msgSender());
    }

    function approveMember() external onlyAdminOrOwner {
        for (uint256 i = 0; i < pendingMembersArr.length; i++) {
            listMembers[pendingMembersArr[i]] = true;
        }
        emit ApproveMembersEvent(_msgSender(), pendingMembersArr);
        pendingMembersArr = new address[](0);
    }

    function joinDAO() external {
        require(
            !listMembers[_msgSender()] &&
                !listAdmins[_msgSender()] &&
                !(_msgSender() == owner()),
            "Already in DAO"
        );
        pendingMembersArr.push(_msgSender());
        emit JoinDAOEvent(_msgSender());
    }
}
