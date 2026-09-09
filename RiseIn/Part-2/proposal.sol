// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    // ****************** Data ***********************

    // Owner
    address owner;

    // Proposal counter
    uint256 private counter;

    struct Proposal {
        string description;          // Description of the proposal
        uint256 approve;             // Number of approve votes
        uint256 reject;              // Number of reject votes
        uint256 pass;                // Number of pass votes
        uint256 total_vote_to_end;   // Number of votes required to end proposal
        bool current_state;          // True = passes, False = fails
        bool is_active;              // Whether users can still vote
    }

    // Stores all proposals
    mapping(uint256 => Proposal) proposal_history;

    // Stores the proposal number on which each address last voted
    mapping(address => uint256) private voted_proposal;


    // ****************** Constructor ***********************

    constructor() {
        owner = msg.sender;
    }


    // ****************** Modifiers ***********************

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this function"
        );
        _;
    }

    modifier active() {
        require(
            proposal_history[counter].is_active,
            "Proposal is not active"
        );
        _;
    }

    modifier newVoter(address _address) {
        require(
            voted_proposal[_address] != counter,
            "Address has already voted"
        );
        _;
    }


    // ****************** Execute Functions ***********************

    function setOwner(address new_owner) external onlyOwner {
        require(
            new_owner != address(0),
            "Invalid owner address"
        );

        owner = new_owner;
    }


    function create(
        string calldata _description,
        uint256 _total_vote_to_end
    ) external onlyOwner {
        require(
            _total_vote_to_end > 0,
            "Vote limit must be greater than zero"
        );

        counter += 1;

        proposal_history[counter] = Proposal(
            _description,
            0,
            0,
            0,
            _total_vote_to_end,
            false,
            true
        );
    }


    function vote(
        uint8 choice
    )
        external
        active
        newVoter(msg.sender)
    {
        require(
            choice <= 2,
            "Invalid voting choice"
        );

        Proposal storage proposal = proposal_history[counter];

        // Record that this address voted on the current proposal
        voted_proposal[msg.sender] = counter;

        // Record the vote
        if (choice == 1) {
            proposal.approve += 1;
        }
        else if (choice == 2) {
            proposal.reject += 1;
        }
        else {
            proposal.pass += 1;
        }

        // Calculate the current state after recording the vote
        proposal.current_state = calculateCurrentState();

        // Calculate total votes after adding the current vote
        uint256 total_vote =
            proposal.approve +
            proposal.reject +
            proposal.pass;

        // End the proposal when the vote limit is reached
        if (total_vote >= proposal.total_vote_to_end) {
            proposal.is_active = false;
        }
    }


    function calculateCurrentState()
        private
        view
        returns (bool)
    {
        Proposal storage proposal = proposal_history[counter];

        uint256 approve = proposal.approve;
        uint256 reject = proposal.reject;
        uint256 pass = proposal.pass;

        // Odd number of pass votes is rounded up
        if (pass % 2 == 1) {
            pass += 1;
        }

        pass = pass / 2;

        if (approve > reject + pass) {
            return true;
        }
        else {
            return false;
        }
    }
}