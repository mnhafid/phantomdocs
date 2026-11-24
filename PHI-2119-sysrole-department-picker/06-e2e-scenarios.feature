# PHI-2119 end-to-end scenarios. One Rule per decision in 01-DECISIONS.md.
# Short names used below:
#   OSF     = stored "Operation & Surface Facilities", Retina prefix "Operations & Surface Facilities"
#   Project = stored "Project", Retina prefix "Projects"
#   PO      = "Production Operations"
#   SDA1    = "Subsurface Development Area 1"
# Test users are mock Retina sessions and must be seeded before the run.

@PHI-2119
Feature: Department picker and permissions from SYSROLE names

  Background:
    Given these test users exist with Phantom SYSROLEs in Retina:
      | user                      | position        | SUBFUNGSI | sysroles                                                                                                                        |
      | phirbac.role.multi        | STAFF           | OSF       | Projects - Read - Guest; Operations & Surface Facilities - Modify - Member; Operations & Surface Facilities - Approval - Member |
      | phirbac.role.single       | STAFF           | Project   | Projects - Modify - Member                                                                                                      |
      | phirbac.role.guest        | STAFF           | Project   | Projects - Read - Guest                                                                                                         |
      | phirbac.role.mismatch     | STAFF           | OSF       | Projects - Read - Guest                                                                                                         |
      | phirbac.role.oldstyle     | TEAM MEMBER     | PO        | Team Member General; Read Only                                                                                                  |
      | phirbac.role.mixed        | STAFF           | Project   | Projects - Read - Guest; Team Member General                                                                                    |
      | phirbac.role.malformed    | STAFF           | PO        | Projects - Read                                                                                                                 |
      | phirbac.role.leader       | STAFF           | Project   | Projects - Modify - Leader                                                                                                      |
      | phirbac.role.leader.cross | STAFF           | Project   | Projects - Modify - Leader; Operations & Surface Facilities - Modify - Member                                                   |
      | phirbac.role.approver     | STAFF           | PO        | Production Operations - Approval - Member                                                                                       |
      | phirbac.role.manager      | MANAGER         | Project   | Projects - Modify - Member                                                                                                      |
      | phirbac.role.unknown      | STAFF           | Project   | Projects - Read - Guest; Finance - Read - Guest                                                                                 |
      | phirbac.role.gm           | GENERAL MANAGER | OSF       | Projects - Modify - Member; Operations & Surface Facilities - Read - Guest                                                      |
      | phirbac.role.gm.oldstyle  | GENERAL MANAGER | OSF       | Project; Operation & Surface Facilities                                                                                         |
      | phirbac.role.gm.leader    | GENERAL MANAGER | OSF       | Projects - Modify - Leader; Production Operations - Modify - Leader                                                             |
      | phirbac.role.sm           | SENIOR MANAGER  | SDA1      | Subsurface Development Area 1 - Modify - Leader                                                                                 |
      | phirbac.role.superadmin   | STAFF           | Project   | Super Admin                                                                                                                     |
      | phirbac.role.foreignadmin | STAFF           | Project   | Projects - Read - Guest                                                                                                         |
      | phirbac.role.none         | STAFF           | PO        |                                                                                                                                 |
    And "phirbac.role.foreignadmin" also holds "Super Admin" on a different Retina system

  @D1
  Rule: A SYSROLE follows the pattern only with at least 3 segments

    Scenario: A name with two segments is treated as old-style
      When "phirbac.role.malformed" logs in
      Then the department is "Production Operations"
      And the permissions are every SYSROLE merged

  @D2
  Rule: The pattern settings come from one place in code

    Scenario: No custom config row is needed
      Given the custom config "organization.sysrole_pattern" does not exist
      When "phirbac.role.single" logs in
      Then the department is "Project"

  @D3
  Rule: Retina prefixes map to the stored department names

    Scenario Outline: Prefix is stored under the existing name
      When a user holding only "<sysrole>" logs in
      Then the department is "<stored>"

      Examples:
        | sysrole                                           | stored                         |
        | Projects - Modify - Member                        | Project                        |
        | Project - Modify - Member                         | Project                        |
        | Operations & Surface Facilities - Modify - Member | Operation & Surface Facilities |
        | Production Operations - Modify - Member           | Production Operations          |
        | Subsurface Development Area 1 - Modify - Member   | Subsurface Development Area 1  |

  @D4
  Rule: Existing records keep working because stored names do not change

    Scenario: Projects data stays visible after the change
      Given contracts exist with department "Project"
      When "phirbac.role.single" logs in and opens the contract list
      Then those contracts are listed

  @D5
  Rule: Old-style SYSROLEs are ignored when a patterned one is held

    Scenario: The old-style role adds nothing
      When "phirbac.role.mixed" logs in
      Then the permissions are exactly those of "Projects - Read - Guest"

  @D6
  Rule: Patterned SYSROLEs decide the department

    Scenario: SYSROLE wins over SUBFUNGSI
      When "phirbac.role.mismatch" logs in
      Then the department is "Project"

    Scenario: SUBFUNGSI is used without a patterned SYSROLE
      When "phirbac.role.oldstyle" logs in
      Then the department is "Production Operations"

  @D7
  Rule: A one-department user is not asked to pick

    Scenario: Goes straight to the dashboard
      When "phirbac.role.single" logs in through the app
      Then the dashboard is shown
      And the Choose Tenant page is not shown
      And Switch Workspace is not in the profile menu

  @D8
  Rule: A multi-department user picks at every login

    Scenario: Forced to the picker
      When "phirbac.role.multi" logs in through the app
      Then the Choose Tenant page is shown
      And other pages redirect to Choose Tenant until a department is picked

    Scenario: The pick is not remembered
      Given "phirbac.role.multi" has picked "Operation & Surface Facilities"
      When "phirbac.role.multi" logs out and logs in again
      Then the department is empty
      And the Choose Tenant page is shown

    Scenario: Switching from the profile menu
      Given "phirbac.role.multi" has picked "Operation & Surface Facilities"
      When "phirbac.role.multi" chooses "Projects" in Switch Workspace
      Then the page reloads
      And the department is "Project"
      And the permissions are exactly those of "Projects - Read - Guest"

  @D9
  Rule: GM, SM and Super Admin keep today's list

    Scenario Outline: The list does not depend on their SYSROLEs
      When "<user>" requests the department options
      Then every department from the existing regulator roles is returned

      Examples:
        | user                    |
        | phirbac.role.gm         |
        | phirbac.role.sm         |
        | phirbac.role.superadmin |

    Scenario: GM is cleared at login
      When "phirbac.role.gm" logs in
      Then the department is empty

  @D10
  Rule: A department gives every SYSROLE under it and nothing else

    Scenario: Modify and Approval combine
      Given "phirbac.role.multi" has picked "Operation & Surface Facilities"
      Then the permissions are the union of "Operations & Surface Facilities - Modify - Member" and "Operations & Surface Facilities - Approval - Member"
      And no permission comes only from "Projects - Read - Guest"

    Scenario: Permissions change without logging in again
      Given "phirbac.role.multi" has picked "Operation & Surface Facilities"
      When "phirbac.role.multi" picks "Project"
      Then the next permissions request returns exactly those of "Projects - Read - Guest"

    Scenario: A token refresh keeps the narrowed set
      Given "phirbac.role.multi" has picked "Project"
      When the token is refreshed
      Then the permissions are exactly those of "Projects - Read - Guest"

    Scenario Outline: Standard SYSROLE types grant the expected access
      When "<user>" logs in
      Then the permissions <result>

      Examples:
        | user                  | result                                  |
        | phirbac.role.guest    | include read access and no modify       |
        | phirbac.role.single   | include read and modify, and no approve |
        | phirbac.role.approver | include read and approve, and no modify |
        | phirbac.role.leader   | include read, modify and approve        |

  @D11
  Rule: With no patterned SYSROLE, everything is merged

    Scenario: Old-style user is merged
      When "phirbac.role.oldstyle" logs in
      Then the permissions are the union of "Team Member General" and "Read Only"
      And the Choose Tenant page is not shown

    Scenario: Old-style GM is merged before picking
      When "phirbac.role.gm.oldstyle" logs in
      Then the permissions are the union of "Project" and "Operation & Surface Facilities"

    Scenario: A pick does not narrow an old-style GM
      When "phirbac.role.gm.oldstyle" picks "Project"
      Then the permissions are the union of "Project" and "Operation & Surface Facilities"

    Scenario: No Phantom SYSROLE at all is rejected at login
      When "phirbac.role.none" logs in
      Then the login is rejected by the existing application gate

  @D12
  Rule: Unpicked users and picks with no matching SYSROLE get 159 only

    Scenario: Before picking
      When "phirbac.role.multi" logs in
      Then the permissions are exactly 159

    Scenario: GM picks a department with no SYSROLE
      When "phirbac.role.gm" picks "Production Operations"
      Then the permissions are exactly 159

    Scenario: GM picks a department with a SYSROLE
      When "phirbac.role.gm" picks "Project"
      Then the permissions are exactly those of "Projects - Modify - Member"

  @D13
  Rule: Super Admin keeps merged permissions

    Scenario: Super Admin stays merged after a pick
      When "phirbac.role.superadmin" picks "Project"
      Then the permissions are every SYSROLE merged

    Scenario: Super Admin on another system does not count
      When "phirbac.role.foreignadmin" logs in
      Then the permissions are exactly those of "Projects - Read - Guest"
      And the user is not a regulator

  @D14
  Rule: Leader or Super Admin in any department gives regulator of the current department

    Scenario: One-department Leader becomes regulator at login
      When "phirbac.role.leader" logs in
      Then the user is regulator of "Project"

    Scenario: Leader of one department picks another
      When "phirbac.role.leader.cross" picks "Operation & Surface Facilities"
      Then the user is regulator of "Operation & Surface Facilities"

    Scenario: Switching moves the regulator role
      Given "phirbac.role.leader.cross" has picked "Operation & Surface Facilities"
      When "phirbac.role.leader.cross" picks "Project"
      Then the user is regulator of "Project"
      And the user is not regulator of "Operation & Surface Facilities"

    Scenario: Keyword matching ignores case
      When a user holding only "Projects - Modify - LEADER" logs in
      Then the user is regulator of "Project"

    Scenario: Super Admin is regulator of the picked department
      When "phirbac.role.superadmin" picks "Project"
      Then the user is regulator of "Project"

    Scenario: Not a regulator before picking
      When "phirbac.role.leader.cross" logs in
      Then the user is not a regulator

  @D15
  Rule: Regulator follows the SYSROLE for everyone

    Scenario: Manager without a Leader SYSROLE is not a regulator
      Given "phirbac.role.manager" currently has the role "regulator of Project"
      When "phirbac.role.manager" logs in
      Then the user is not a regulator

    Scenario: Regulator is removed when the SYSROLE goes
      Given "phirbac.role.leader" is regulator of "Project"
      And "Projects - Modify - Leader" is replaced in Retina by "Projects - Modify - Member"
      When "phirbac.role.leader" logs in
      Then the user is not a regulator

    Scenario: SM with a Leader SYSROLE becomes regulator
      When "phirbac.role.sm" picks "Subsurface Development Area 1"
      Then the user is regulator of "Subsurface Development Area 1"

    Scenario: GM without a Leader SYSROLE is not a regulator
      When "phirbac.role.gm" picks "Project"
      Then the user is not a regulator

    Scenario Outline: Non-Leader SYSROLE types never give regulator
      When "<user>" logs in
      Then the user is not a regulator

      Examples:
        | user                  |
        | phirbac.role.guest    |
        | phirbac.role.single   |
        | phirbac.role.approver |

  @D23
  Rule: GM and SM mapped to Leader are regulators

    Scenario: GM Leader becomes regulator of the picked department
      When "phirbac.role.gm.leader" picks "Project"
      Then the user is regulator of "Project"
      And the permissions are exactly those of "Projects - Modify - Leader"

    Scenario: GM Leader picks a department with no SYSROLE
      When "phirbac.role.gm.leader" picks "Operation & Surface Facilities"
      Then the user is regulator of "Operation & Surface Facilities"
      And the permissions are exactly 159

  @D16
  Rule: Each department has at least four SYSROLEs

    Scenario Outline: The four SYSROLEs exist
      Then Retina has these SYSROLEs for system "PHANTOM":
        | <department> - Modify - Leader   |
        | <department> - Modify - Member   |
        | <department> - Read - Guest      |
        | <department> - Approval - Member |

      Examples:
        | department                      |
        | Projects                        |
        | Operations & Surface Facilities |
        | Production Operations           |
        | Subsurface Development Area 1   |
        | Subsurface Development Area 2   |

  @D17
  Rule: Existing responses do not change

    Scenario Outline: Response shape is unchanged
      When "phirbac.role.multi" calls "<endpoint>"
      Then the response has no new fields

      Examples:
        | endpoint                  |
        | POST /auth/login          |
        | GET /users/profile        |
        | POST /users/me/department |

    Scenario: Options keep their shape
      When "phirbac.role.multi" requests the department options
      Then each item has only "department" and "division"

  @D18
  Rule: The options list decides what FE shows

    Scenario Outline: Options per user
      When "<user>" requests the department options
      Then the options are "<options>"

      Examples:
        | user                  | options                                 |
        | phirbac.role.multi    | Project, Operation & Surface Facilities |
        | phirbac.role.single   |                                         |
        | phirbac.role.oldstyle |                                         |

    Scenario: Switch Workspace appears after picking
      Given "phirbac.role.multi" has picked "Project"
      Then Switch Workspace is in the profile menu
      And the Choose Tenant page is not shown

    Scenario: A STAFF user can reach the picker
      Given "phirbac.role.multi" has position "STAFF"
      When "phirbac.role.multi" logs in through the app
      Then the Choose Tenant page is shown

    Scenario: A user with no department and no options is rejected, not sent to the picker
      Given "phirbac.role.malformed" has an empty SUBFUNGSI
      When "phirbac.role.malformed" calls any authenticated endpoint
      Then the response is 401 "User has no active department scope"

  @D19
  Rule: Cards are built from the options list

    Scenario: Only the user's departments are shown
      When "phirbac.role.multi" opens the Choose Tenant page
      Then only the PnP group is offered
      And the cards are "Projects" and "OSF"
      And no SSDP card is shown

    Scenario: A pick reloads with fresh permissions
      When "phirbac.role.multi" clicks the "Projects" card
      Then "POST /users/me/department" is sent with "Project"
      And the app does a full page load

  @D20
  Rule: Unknown departments are offered under Other

    Scenario: Unknown department gets the Phantom logo
      When "phirbac.role.unknown" opens the Choose Tenant page
      And "phirbac.role.unknown" selects the "Other" group
      Then a "Finance" card with the Phantom logo is shown

    Scenario: Unknown department can be picked
      When "phirbac.role.unknown" picks "Finance"
      Then the department is "Finance"
      And the permissions are exactly those of "Finance - Read - Guest"

  @D21
  Rule: A pick the user does not hold is rejected

    Scenario: Direct POST for a department not held
      Given "phirbac.role.multi" is logged in
      When "phirbac.role.multi" posts the department "Production Operations" directly
      Then the request is rejected
      And the department is unchanged

    Scenario: A one-department user cannot post another department
      Given "phirbac.role.single" is logged in
      When "phirbac.role.single" posts the department "Operation & Surface Facilities" directly
      Then the request is rejected

    Scenario: GM may pick a department not held
      When "phirbac.role.gm" posts the department "Production Operations" directly
      Then the request succeeds

  @D22
  Rule: The logo falls back to the general Phantom logo

    Scenario Outline: Fallback cases
      Given the profile has <state>
      When the sidebar is shown
      Then the general Phantom logo is shown

      Examples:
        | state                    |
        | no organisation          |
        | an empty department      |
        | the department "Finance" |

    Scenario: Known department keeps its logo
      Given "phirbac.role.single" is logged in
      When the sidebar is shown
      Then the Projects logo is shown
