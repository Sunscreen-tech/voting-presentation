---
title: Private voting with Fully Homomorphic Encryption
subtitle: Confidential voting made easy
author: Ryan Orendorff
date: 2025
theme: metropolis
monofont: "Iosevka"
header-includes: |
  \definecolor{BerkeleyBlue}{RGB}{0,50,98}
  \definecolor{FoundersRock}{RGB}{59,126,161}
  \definecolor{Medalist}{RGB}{196,130,14}

  \setbeamercolor{frametitle}{fg=white,bg=FoundersRock}
  \setbeamercolor{title separator}{fg=Medalist,bg=white}

  \usepackage{fontspec}
  \setmonofont{Iosevka}
  \usefonttheme[onlymath]{serif}

  \usepackage{tikz}
  \usetikzlibrary{shapes.geometric,positioning,arrows.meta}
---

## Who is Sunscreen?

![logo](figs/sunscreen.png) \

\centerline{Ultra-fast, easy-to-use Fully Homomorphic Encryption infrastructure}

1. We build Fully Homomorphic Encryption (FHE) tooling, including a compiler and processor.
2. Our mission is to make data privacy easy and accessible for every developer.
3. We believe FHE is an integral part of the future of data privacy.

## Outline

- Basics of Fully Homomorphic Encryption
- Building voting systems: from binary to ranked choice
- Integrating with blockchain using SPF
- Live demonstration
- Other FHE applications

# Basics of Fully Homomorphic Encryption

## Normally, a server needs to see your data to process it

While data is often encrypted in transit from a user to a server, the server must decrypt that data to be able to process a request.

![Server processing](figs/server-processing-standard.png)

. . .

This represents a data privacy concern; the server operator could mishandle your data.

## FHE allows computation on encrypted data without decryption

Fully Homomorphic Encryption (FHE) enables servers to perform computations on encrypted data without ever decrypting it.

![FHE processing](figs/server-processing-fhe.png)

. . .

The server can never read your data.

## How FHE accomplishes this: base operations

FHE schemes support two primary operations on ciphertexts that have the following properties (homomorphisms):

::: incremental

- Addition: $\mathrm{Enc}(a) + \mathrm{Enc}(b) = \mathrm{Enc}(a + b)$
- Multiplication: $\mathrm{Enc}(a) \cdot \mathrm{Enc}(b) = \mathrm{Enc}(a \cdot b)$

:::

The term 'fully' means it can compute any function on encrypted data.

## Torus FHE enables efficient comparison operations

Sunscreen has its own variant of the Torus FHE scheme, which allows for efficient comparison operations as well.

\begin{center}
\begin{tikzpicture}[>=Stealth, thick]
% Define the trapezoid shape for the mux
\coordinate (topleft) at (0,1);
\coordinate (topright) at (2,0.5);
\coordinate (bottomright) at (2,-0.5);
\coordinate (bottomleft) at (0,-1);

% Draw the mux body
\draw[fill=blue!10] (topleft) -- (topright) -- (bottomright) -- (bottomleft) -- cycle;

% Draw input lines
\draw (-1.5,0.5) -- (0,0.5) node[midway,above] {a};
\draw (-1.5,-0.5) -- (0,-0.5) node[midway,above] {b};

% Draw select line
\draw (1,1.5) -- (1,1) node[above] at (1,2) {sel};

% Draw output line
\draw (2,0) -- (3.5,0) node[right,above] {if sel then a else b};

% Add MUX label in the center
\node at (1,0) {\Large cmux};
\end{tikzpicture}
\end{center}

Using this computation allows us to build out FHE-based circuits, much like one would do with standard computer hardware.

## So what can we compute with TFHE?

Sunscreen's variant of TFHE supports the following 64-bit operations on plaintext or ciphertext data.

- Arithmetic operations (add, sub, mul)
- Logical operations (and, or, not)
- Bit operations (shifts)
- Comparison operations (equal, less than, greater than)
- Branching (cmux)
- Arrays

## The Sunscreen stack: a modular FHE compute engine

:::::::::::::: {.columns}
::: {.column width="50%"}

The Sunscreen TFHE stack is a complete compute system. Most importantly, this stack includes:

1. A compiler that converts C code to FHE programs.
2. An off-chain compute service for high-performance blockchains and dApps.

:::
::: {.column width="50%"}
![Secure Processing Framework](figs/architecture-stack.png)
:::
::::::::::::::

## Why is voting a good FHE application?

Private voting is an ideal application for FHE because it requires:

::: incremental

- Ballot secrecy: votes must remain confidential during counting
- Verifiable execution: the election process must be auditable (through deterministic outputs)
- Complex computation: tallying requires data validation and transformation

:::

FHE enables all of these properties simultaneously.

# Let's build voting systems with FHE!

## Binary voting: choosing if an issue passes or fails

Our first voting scheme will be binary voting, where voters choose whether to accept or reject an issue.

. . .

The basic process for tallying these votes is to

- Collect encrypted yes/no votes from voters
- Tally the votes homomorphically
- Determine if the issue passes based on majority

## Binary voting: the plaintext code

This specifies whether an issue passes if the majority of voters vote "yes".

```c
#include <parasol.h>


void binary_vote_plain(uint8_t *voter_choices,
                       uint16_t num_voters,
                       bool *issue_passes) {
    uint16_t tally = 0;
    for (uint16_t i = 0; i < num_voters; i++) {
        // Coerce to boolean (0 or 1)
        tally += (bool) voter_choices[i];
    }
    *issue_passes = tally > (num_voters / 2);
}
```

## Binary voting: the encrypted code

This specifies whether an issue passes if the majority of voters vote "yes".

```c
#include <parasol.h>

[[clang::fhe_program]]
void binary_vote([[clang::encrypted]] uint8_t *voter_choices,
                 uint16_t num_voters,
                 [[clang::encrypted]] bool *issue_passes) {
    uint16_t tally = 0;
    for (uint16_t i = 0; i < num_voters; i++) {
        // Coerce to boolean (0 or 1)
        tally += (bool) voter_choices[i];
    }
    *issue_passes = tally > (num_voters / 2);
}
```

## Quadratic voting: binary voting with more numbers

<!--

```c
inline bool is_valid_quad(int16_t voter_choice, uint16_t voter_credit) {
  // Handle negative votes by computing absolute value without branches
  bool is_negative = voter_choice < 0;
  int16_t abs_choice = iselect16(is_negative, -voter_choice, voter_choice);

  // Square the absolute value (cast to prevent overflow)
  uint32_t choice_squared = (uint32_t)abs_choice * (uint32_t)abs_choice;

  // Check if squared value is within voter power
  return choice_squared <= (uint32_t)voter_credit;
}
```

-->

Binary voting can be extended to quadratic voting by allowing users to cast n votes that have a quadratic cost.

```c
[[clang::fhe_program]]
void quadratic_vote([[clang::encrypted]] int16_t *voter_choices,
                    [[clang::encrypted]] uint16_t *voter_credits,
                    uint16_t num_voters,
                    [[clang::encrypted]] bool *issue_passes) {
    int32_t tally = 0;
    for (uint16_t i = 0; i < num_voters; i++) {
        bool valid = is_valid_quad(voter_choices[i], voter_credits[i]);
        tally += iselect16(valid, voter_choices[i], 0);
    }
    *issue_passes = tally > 0;
}
```

## Binary voting: a good first start

We can now choose between two options privately!

. . .

This method can be extended to quadratic voting, where voters can assign values beyond zero or one.

. . .

However, what if we wanted to run a more complex election with multiple candidates?

## First past the post: choosing a candidate from multiple options

In first past the post (FPTP) voting, each voter selects one candidate from a list of options.

. . .

This requires a few more pieces on top of binary voting:

- Verifying voter choices.
- Converting the data into something that can be tallied.
- Finding the winner among the final tally.

## First past the post: encoding the vote

We want to tally the votes for each candidate. To facilitate this, we will convert each voter's choice into an array with a single `1` in it.

```c
inline void encode_ballot(
    [[clang::encrypted]] uint8_t choice,
    uint8_t num_choices,
    [[clang::encrypted]] uint8_t *encoded_ballot) {
    uint8_t is_valid_ballot = choice < num_choices;

    for (uint8_t i = 0; i < num_choices; i++) {
        // We turn invalid votes into ballots of all zeros.
        encoded_ballot[i] = select8(choice == i, is_valid_ballot, 0);
    }
}
```

## First past the post: tally helpers

We need some helpers for handling the tally process.

```c
inline void initialize_tally([[clang::encrypted]] uint16_t *tally,
                             uint8_t num_choices) {
    for (uint8_t choice = 0; choice < num_choices; choice++)
        tally[choice] = 0;
}

inline void add_to_tally([[clang::encrypted]] uint8_t *ballot,
                         [[clang::encrypted]] uint16_t *tally,
                         uint16_t num_choices) {
    for (uint8_t choice = 0; choice < num_choices; choice++)
        tally[choice] += ballot[choice];
}
```

## First past the post: tallying the votes

Tallying the votes involves converting all ballots to the encoded form and then summing all ballots.

```c
inline void tally_votes([[clang::encrypted]] uint8_t *ballots,
                        uint16_t num_ballots, uint8_t num_choices,
                        [[clang::encrypted]] uint16_t *tally,
                        [[clang::encrypted]] uint8_t *encoded_ballot) {
    initialize_tally(tally, num_choices);
    for (uint8_t i = 0; i < num_ballots; i++) {
        encode_ballot(ballots[i], num_choices, encoded_ballot);
        add_to_tally(encoded_ballot, tally, num_choices);
    }
}
```

<!--

## First past the post: what we've seen so far

::: incremental

- Vote validation: ensuring choices are in valid range
- Ballot encoding: converting choices to countable arrays
- Tallying: summing encoded ballots

:::

. . .

Now we need to find the winner from the tally.

-->

## First past the post: deciding the winner

As the last step, we can find the winner from the final tally by selecting the candidate with the most votes.

```c
inline void determine_winner([[clang::encrypted]] uint16_t *tally,
                             uint8_t num_choices,
                             [[clang::encrypted]] uint8_t *winner) {
    *winner = 0; uint16_t max_votes = tally[0];

    for (uint8_t choice = 1; choice < num_choices; choice++) {
        bool is_greater = tally[choice] > max_votes;

        max_votes = select16(is_greater, tally[choice], max_votes);
        *winner = select8(is_greater, choice, *winner);
    }
}
```

## First past the post: full election circuit

We can now call all our functions in one main program.

```c
[[clang::fhe_program]]
void fptp_election([[clang::encrypted]] uint8_t *ballots,
                   uint16_t num_ballots, uint8_t num_choices,
                   [[clang::encrypted]] uint16_t *tally,
                   [[clang::encrypted]] uint8_t *encoded_ballot,
                   [[clang::encrypted]] uint8_t *winner) {
    tally_votes(
        ballots, num_ballots, num_choices, tally, encoded_ballot);
    determine_winner(tally, num_choices, winner);
}
```

## First past the post: full elections with validations

With first past the post, we saw

- Data validation.
- Converting between data structures (int and array) for counting.
- Use of scratch buffers (must be passed in).

. . .

Can we take this one step further and enable people to rank their preferences instead of just picking one?

## Ranked choice voting: ranking candidates by preference

In ranked choice voting, each voter ranks candidates in order of preference. Points are assigned based on the rank, and the candidate with the highest total points wins.

```
ballot = [
  0, // Give 0 points to the first candidate
  3, // Give 3 points to the second candidate
  2, // Give 2 points to the third candidate
  1  // Give 1 point to the fourth candidate
]
```

<!--

## Borda count: ballots are encoded

When users submit ballots for the Borda count, they will do so by indicating their point values as a specific bit being on. This is to make ballot validation easier.

```
ballot = [
  0b0001, // Points assigned to 1st candidate (0)
  0b1000, // Points assigned to 2nd candidate (3)
  0b0100, // Points assigned to 3rd candidate (2)
  0b0010  // Points assigned to 4th candidate (1)
]
```

Including this code for parsing but not explaining it in detail, as it's a bit much for this presentation.

```c
#include <parasol.h>

inline uint8_t get_bit(uint8_t value, uint8_t bit_pos) {
    return (value >> bit_pos) & 1;
}

inline bool is_one_hot(uint8_t value, uint8_t n) {
    bool has_one_bit = ((value & (value - 1)) == 0) && (value != 0);
    bool in_range = (value <= ((1 << n) - 1));
    return has_one_bit && in_range;
}

inline bool validate_borda_ballot(
    [[clang::encrypted]] uint8_t *one_hot_array,
    uint8_t n
) {
    uint8_t xor_result = 0; bool all_one_hot = true;

    for (uint8_t i = 0; i < n; i++) {
        xor_result ^= one_hot_array[i];
        all_one_hot = all_one_hot && is_one_hot(one_hot_array[i], n);
    }

    return (xor_result == ((1 << n) - 1)) && all_one_hot;
}

inline uint8_t decode_bit(uint8_t one_hot_value, uint8_t n) {
    uint8_t value = 0;
    for (uint8_t bit = 0; bit < n; bit++) {
        value = select8(get_bit(one_hot_value, bit), bit, value);
    }
    return value;
}
```

## Borda count: converting encoded ballots back to values

The first step in the Borda count is to take the encoded ballots, validate them, and convert them into point values.

```c
[[clang::fhe_program]]
void decode_borda_ballot(
    [[clang::encrypted]] uint8_t *encoded_ballot,
    uint8_t n,
    [[clang::encrypted]] uint8_t *decoded_ballot
) {
    bool is_valid = validate_borda_ballot(encoded_ballot, n);
    for (uint8_t i = 0; i < n; i++) {
        uint8_t value = decode_bit(encoded_ballot[i], n);
        decoded_ballot[i] = select8(is_valid, value, 0);
    }
}
```

-->

## Ranked choice voting: similar to FPTP with different ballots

We can implement ranked choice voting with the Borda method.

```c
[[clang::fhe_program]]
void borda_election([[clang::encrypted]] uint8_t *ballots,
                    uint16_t num_ballots, uint8_t num_choices,
                    [[clang::encrypted]] uint16_t *tally,
                    [[clang::encrypted]] uint8_t *decoded_ballot,
                    [[clang::encrypted]] uint8_t *winner) {
    initialize_tally(tally, num_choices);
    for (uint16_t i = 0; i < num_ballots; i++) {
        decode_borda_ballot(
            &ballots[i * num_choices], num_choices, decoded_ballot);
        add_to_tally(decoded_ballot, tally, num_choices);
    }
    determine_winner(tally, num_choices, winner);
}
```

## Ranked choice voting: what did we learn?

Ranked choice voting is a demonstration of more complex voting methods.

. . .

Specifically, it also shows that you can build up _a library of composable FHE programs_ that can be reused in other scenarios (`add_to_tally`, `determine_winner`, etc).

## Are any voting systems off-limits?

One strongly desired property of a voting system is called the _Condorcet condition_, which states that _the candidate who wins the most head-to-head matchups should win the overall election_.

- Majority rule: more than half of the voters are satisfied with the result
- Reduces the effect of spoiler candidates
- Encourages candidates to appeal to a broader electorate

. . .

The Borda method shown can be extended to be a Condorcet election method in FHE using the Copeland election scheme.

<!--

## Copeland method: full election circuit


```c
[[clang::fhe_program]]
void copeland_election(
    [[clang::encrypted]] uint8_t *ballots,
    uint16_t num_ballots,
    uint8_t num_choices,
    [[clang::encrypted]] uint16_t *pairwise_matrix,
    [[clang::encrypted]] uint8_t *decoded_ballot,
    [[clang::encrypted]] uint16_t *wins,
    [[clang::encrypted]] uint16_t *losses,
    [[clang::encrypted]] uint8_t *winner) {

    // Initialize pairwise preference matrix
    for (uint8_t i = 0; i < num_choices * num_choices; i++) {
        pairwise_matrix[i] = 0;
    }

    // Count pairwise preferences from ranked ballots
    for (uint16_t ballot_idx = 0; ballot_idx < num_ballots; ballot_idx++) {
        uint8_t *ballot = &ballots[ballot_idx * num_choices];
        decode_borda_ballot(ballot, num_choices, decoded_ballot);

        // For each pair of candidates, check which is preferred
        for (uint8_t i = 0; i < num_choices; i++) {
            for (uint8_t j = 0; j < num_choices; j++) {
                if (i != j) {
                    // Lower rank value means higher preference
                    bool i_preferred = decoded_ballot[i] < decoded_ballot[j];
                    uint16_t increment = select16(i_preferred, 1, 0);
                    pairwise_matrix[i * num_choices + j] += increment;
                }
            }
        }
    }

    // Calculate wins and losses for each candidate
    for (uint8_t i = 0; i < num_choices; i++) {
        wins[i] = 0;
        losses[i] = 0;
    }

    for (uint8_t i = 0; i < num_choices; i++) {
        for (uint8_t j = i + 1; j < num_choices; j++) {
            uint16_t i_over_j = pairwise_matrix[i * num_choices + j];
            uint16_t j_over_i = pairwise_matrix[j * num_choices + i];

            bool i_wins_pair = i_over_j > j_over_i;
            bool j_wins_pair = j_over_i > i_over_j;

            wins[i] += select16(i_wins_pair, 1, 0);
            losses[i] += select16(j_wins_pair, 1, 0);

            wins[j] += select16(j_wins_pair, 1, 0);
            losses[j] += select16(i_wins_pair, 1, 0);
        }
    }

    // Find candidate with highest Copeland score (wins - losses)
    // Use comparison: wins[i] + losses[max] > wins[max] + losses[i]
    *winner = 0;
    uint16_t max_wins = wins[0];
    uint16_t max_losses = losses[0];

    for (uint8_t choice = 1; choice < num_choices; choice++) {
        bool is_greater = (wins[choice] + max_losses) > (max_wins + losses[choice]);
        max_wins = select16(is_greater, wins[choice], max_wins);
        max_losses = select16(is_greater, losses[choice], max_losses);
        *winner = select8(is_greater, choice, *winner);
    }
}
```

-->

## What did we learn about voting with FHE?

We have seen FHE implementations of core components of a voting scheme.

- FHE can handle complex data validation and transformation.
- Many voting systems can be implemented homomorphically, including sophisticated methods like the Copeland method.
- FHE preserves voter privacy throughout the process.

. . .

How do we use FHE to bring these private voting methods to web3?

# Voting onchain with the Secure Processing Framework (SPF)

## What we've built so far

::: incremental

- Binary voting: simple majority decisions
- First past the post: multi-candidate selection with validation
- Borda count: ranked preference with bit-encoded ballots

:::

. . .

These are standalone FHE programs. To make them useful onchain, we need infrastructure.

<!--

## FHE (or any DeCC method) is only part of the voting solution

While FHE enables private computation, a complete voting system also requires:

- Voter authentication: did the right people vote?
- Trusted operation: was the election run properly?
- Access control: when the final tally is done, who gets to see it?

-->

## Secure Processing Framework (SPF) brings FHE onchain

:::::::::::::: {.columns}
::: {.column width="50%"}

The Secure Processing Framework (SPF) is Sunscreen's solution for integrating FHE into blockchain environments.

- An oracle listening to FHE operations onchain.
- A data storage system for encrypted data.
- An access control system to manage who can run programs and decrypt results.

:::
::: {.column width="50%"}
![Secure Processing Framework](figs/architecture-stack.png)
:::
::::::::::::::

## SPF allows developers to call FHE applications from smart contracts

:::::::::::::: {.columns}
::: {.column width="40%"}

::: incremental

1. Write an FHE application using Sunscreen's compiler
2. Write a smart contract to call the FHE program
3. Upload the FHE application to the SPF service
4. Deploy the smart contract to the blockchain
5. SPF listens for FHE events
6. SPF calls contract callback to post results

:::
:::
::: {.column width="60%"}
![Developer workflow in web3](figs/web3-steps.png)
:::
::::::::::::::

## To make a smart contract with FHE, we need to know a few things

We need to know the following information:

::: incremental

1. The function signature in C.
2. A callback function for how to handle the results.

:::

## Let's wrap the binary voting example

We will build up the contract for binary voting in parts. First, we define some state for our contract.

```solidity
import "@sunscreen/contracts/Spf.sol";
import "@sunscreen/contracts/TfheThresholdDecryption.sol";

contract BinaryVoting is TfheThresholdDecryption {
  Spf.SpfLibrary public constant VOTING_SPF_LIBRARY =
      Spf.SpfLibrary.wrap(hex"edd540489dac8e6dab39c9f99aa6a3fc"
                          hex"100c96899e772286800b0bd1ac6479ee");
  Spf.SpfProgram public constant VOTING_PROGRAM =
      Spf.SpfProgram.wrap("binary_vote");

  Spf.SpfParameter[] public votes;
  bool public issuePassed;
```

## Users provide votes through their ciphertext identifier

This returns an identifier that the user can use to reference their data onchain.

```solidity
  function submitVote(Spf.SpfParameter calldata vote) public {
      Spf.SpfParameter memory updatedVote =
        Spf.senderAllowCurrentContractRun(
          vote, VOTING_SPF_LIBRARY, VOTING_PROGRAM);
      votes.push(updatedVote);
  }
```

## Packing votes together

Remember we have this syntax for our binary vote program.

```{.c include=false}
void binary_vote([[clang::encrypted]] uint8_t *voter_choices,
                 uint16_t num_voters,
                 [[clang::encrypted]] bool *issue_passes);
```

. . .

We can tell Solidity how to pack these parameters into the run request.

```solidity
function packParameters() internal view
  returns (Spf.SpfParameter[] memory) {
    return Spf.pack3Parameters(
        Spf.createCiphertextArrayFromParams(votes),
        Spf.createPlaintextParameter(16, votes.length),
        Spf.createOutputCiphertextParameter(8));
}
```

## Running the binary voting program

We can then run the program:

```solidity
function run() public {
    Spf.SpfParameter[] memory parameters = packParameters();

    // Request the FHE program be run off-chain
    Spf.SpfRunHandle runHandle = Spf.requestRunAsContract(
        VOTING_SPF_LIBRARY, VOTING_PROGRAM, parameters);
    Spf.SpfParameter memory issuePasses = Spf.getOutputHandle(
        runHandle, 0);

    // Request the FHE result be posted onchain
    requestDecryptionAsContract(this.postResult.selector,
        Spf.passToDecryption(issuePasses));
}
```

Gate this function to run only when the desired criteria are met (`onlyAdmin`, all parties have voted, etc).

## Decryption

When the binary voting computation is complete, the SPF oracle will post the results back onchain through the specified callback.

```solidity
function postResult(bytes32 identifier, uint256 _issuePassed)
    public onlyThresholdDecryption {
    issuePassed = (_issuePassed != 0);
}
```

<!--

Contract closing paren

```solidity
}
```

-->

The `identifier` is passed in to allow the contract to keep track of which value is being decrypted in case multiple values could be returned.

## SPF enables onchain voting

The SPF service enables onchain private voting using FHE.

::: incremental

- Ballot secrecy: FHE keeps the ballots private during the tally process.
- Verifiable execution: the coordinating smart contract is auditable, and the FHE program being run is known by a verifiable identifier.
- Auditability: computations can be rerun by anyone (but not decrypted) to verify the output ciphertext is correct.

:::

# Demo time!

## Private voting

Let's walk through binary voting as a dApp.

![https://voting-demo.sunscreen.tech](figs/qr-voting-demo.png){width=50%}

## Beyond voting

The techniques demonstrated in voting—data validation, transformation, and conditional logic on encrypted data—enable private computation across many domains.

# Uses for Sunscreen FHE stack

## FHE for private auctions

FHE can be used to build private auctions:

- First/second price sealed bid auctions
- Bid for priority to some resource
- MEV auctions: private bids prevent frontrunning and protect block builder strategies

## FHE for private payments

FHE can enable private ERC20 and other token payments.

```c
[[clang::fhe_program]]
void balance_transfer([[clang::encrypted]] uint64_t *sender_balance,
                      [[clang::encrypted]] uint64_t *recipient_balance,
                      [[clang::encrypted]] uint64_t transfer_amount,
                      [[clang::encrypted]] uint64_t zero) {
    // Set invalid transfer amount to 0
    bool has_sufficient = transfer_amount <= *sender_balance;
    uint64_t transfer_value = has_sufficient ? transfer_amount : zero;

    // Update balances
    *recipient_balance += transfer_value;
    *sender_balance -= transfer_value;
}
```

All operations execute on encrypted data—the server validates sufficient balance and performs the transfer without ever seeing actual amounts.

## FHE for data transformations

FHE enables complex data transformations to happen privately.

- Private recommendation engines based on encrypted user preferences
- Confidential credit scoring and applicant ranking
- Private ML inference

## FHE for private database lookups (PIR)

FHE can be used to make a database where lookups are private; the database operator does not know what someone looked for.

- Search
- Financial services (screening)
- Caller ID
- Visual search

## FHE powers a private and verifiable blockchain ecosystem

What we've demonstrated:

- Complete voting systems: from C code to onchain execution
- Privacy preservation: ballot secrecy throughout the entire process
- Verifiability: auditable smart contracts and replayable computations

The same principles extend to auctions, payments, ML inference, and database queries—any computation requiring confidentiality with verification.

## Questions?

:::::::::::::: {.columns}
::: {.column width="50%"}
![https://spf-docs.sunscreen.tech](figs/qr-spf-docs.png)

SPF documentation
:::
::: {.column width="50%"}
![https://docs.sunscreen.tech](figs/qr-processor-docs.png)

Parasol documentation
:::
::::::::::::::
