// D
import std.array;
import std.conv;
import std.json;
import std.getopt;
import std.net.curl;
import std.process;
import std.stdio;

struct input {
    string github_name = "";
    string github_repo = "";    
    string oauth_token = "";
    string ci_path = "";
    string ci_script = "";
}

void main(string[] args) {
    input user_inputs;
    string github_response = "";
    JSONValue github_response_json = null;
    string new_commit = "";
    string old_commit = new_commit;
    string new_commit_date = "";

    if(args.length == 1) 
    {
        writeln("No input arguments. Exiting IntegrateD.");
        return;
    } 

    auto helpInformation = getopt
    (
        args,
        "github_name", &user_inputs.github_name,
        "github_repo", &user_inputs.github_repo,    
        "oauth_token", &user_inputs.oauth_token,    
        "ci_path", &user_inputs.ci_path, 
        "ci_script", &user_inputs.ci_script,   
        config.stopOnFirstNonOption
    ); 

    string http_call = "https://api.github.com/repos/"~
        user_inputs.github_name~"/"~user_inputs.github_repo~
        "/commits";
    writeln("[IntegrateD] Http call: "~http_call);
    writeln("[IntegrateD] Script:" ~ user_inputs.ci_script);
    writeln("[Integrated] Workspace: " ~ user_inputs.ci_path);
    auto client = HTTP(http_call);
    client.addRequestHeader("Authorization", 
        "token " ~ user_inputs.oauth_token);
    client.onReceive = (ubyte[] data) {
        github_response ~= cast(char[]) data; 
        return data.length;
    };

    while(1) {
        client.perform();
        github_response_json = parseJSON(github_response);
        if(github_response_json.type == JSON_TYPE.ARRAY) {
            new_commit = to!string(
                github_response_json[0]["sha"]);
            new_commit_date = to!string(
                github_response_json[0]["commit"]["author"]["date"]);
            if(new_commit != old_commit) {
                if(old_commit == "") {
                    writeln("[IntegrateD] Entering CI.");
                    writeln("[IntegrateD] Latest commit: "~
                        user_inputs.github_repo~
                        " is "~
                        new_commit ~ 
                        " time stamp is " ~ new_commit_date);
                } 
                else {
                writeln("[IntegrateD] Old commit: "~
                    user_inputs.github_repo~
                    " is "~
                    old_commit);
                writeln("[IntegrateD] New commit: "~
                    user_inputs.github_repo~
                    " is "~
                    new_commit ~ 
                    " time stamp is " ~ new_commit_date);                    
                }

                old_commit = new_commit;
                if(
                    user_inputs.ci_path != "" &&
                    user_inputs.ci_script != "") 
                {
                    auto result = executeShell(
                        user_inputs.ci_script,
                        null,
                        Config.none,
                        size_t.max,
                        user_inputs.ci_path);
                    writeln(result.output);  
                    writeln("[IntegrateD] CI finished.");
                }
                else writeln("[IntegrateD] CI script or path not found.");
            }      
        }
    }
}