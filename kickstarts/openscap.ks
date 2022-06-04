# OpenSCAP parameters
%addon com_redhat_oscap
    content-type = scap-security-guide
    content-path = %SCAP_CONTENT%
    datastream-id = %SCAP_ID_DATASTREAM%
    xccdf-id = %SCAP_ID_XCCDF%
    profile = %SCAP_PROFILE%
%end
