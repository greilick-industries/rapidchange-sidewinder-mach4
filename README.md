README.md
RapidChangeATC scripts are responsible for execution of the following:
m6():
- find reasons not to execute
    - selected tool == current tool
    - machine is not enabled
    - machine is not homed
- call m114()
- record & save relevant current machine states
- unload existing tool
- load selected tool
 - set current tool
- restore relevant machine states
- call m1005()
- call m115()

m114():
    - find reasons not to execute
        - cover is already open
        - machine is not enabled
        - machine is not homed
    - record & save relevant current machine states
    - open dust cover
    - restore relevant machine states
    - set dust cover signal

m115():
    - find reasons not to execute
        - cover is already closed
        - machine is not enabled
        - machine is not homed
    - record & save relevant current machine states
    - close dust cover
    - restore relevant machine states
    - set dust cover signal

m1005():
    - find reasons not to execute
        - machine is not enabled
        - machine is not homed
    - record & save relevant current machine states
    - probe tool length
    - restore relevant machine states
    - activate tool length offset

Process/Policy:
    - each macro is responsible for safe execution of g-code
        if x,y,z motion is to occur:
        - m5
        - raise spindle to safe location at beginning AND end
    - each step requires the previous step to be successful
    - if a step is not successful
        - attempt to restore relevant machine states
        - inform reason for failure
        - stop progress in gentlest way possible, but E-Stop machine if necessary

Signals:
RapidChangeATC scripts are NOT responsible for the following:
    - user custom features of m6(), m114(), m115(), m1005() macros
    - checking/enabling/disabling soft limits
    - checking/enabling/disabling coolant
    - checking/enabling/disabling dust collection
    - starting spindle upon successful execution
