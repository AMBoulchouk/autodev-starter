# Feature: Approve order

## Objective

Allow an authorized actor to approve a pending order.

## Actor

Manager.

## Preconditions

- The order exists.
- The order status is `pending`.

## Rules

- Orders over 10,000 require manager approval.
- Orders over 100,000 require director approval.
- Rejected orders cannot be approved.

## Result

The order status becomes `approved`.

## Acceptance criteria

### Scenario: valid manager approval

Given a pending order for 25,000
And the actor is a manager
When the actor approves the order
Then the order status becomes approved
And an approval timestamp is recorded

### Scenario: insufficient authorization

Given a pending order for 150,000
And the actor is a manager
When the actor attempts to approve the order
Then the operation is rejected
And the order remains pending
