// D
import std.array;
import std.conv;
import std.json;
import std.getopt;
import std.net.curl;
import std.stdio;

struct input {
    string ci_path = "";
    string oauth_token = "";
    string github_name = "";
    string github_repo = "";
}

void main(string[] args) {
    input user_inputs;
    string result = "";
    JSONValue result_json = null;
    string new_commit = "";
    string old_commit = new_commit;
    string new_commit_date = "";

    auto helpInformation = getopt
    (
        args,
        "github_name", &user_inputs.github_name,
        "github_repo", &user_inputs.github_repo,    
        "oauth_token", &user_inputs.oauth_token,    
        "ci_path", &user_inputs.ci_path,    
        config.stopOnFirstNonOption
    ); 

    auto client = HTTP(
        "https://api.github.com/repos/"~
        user_inputs.github_name~"/"~user_inputs.github_repo~
        "/commits");
    client.addRequestHeader("Authorization", 
        "token " ~ user_inputs.oauth_token);
    client.onReceive = (ubyte[] data) {
        result ~= cast(char[]) data; 
        return data.length;
    };

    while(1) {
        client.perform();
        result_json = parseJSON(result);
        if(result_json.type == JSON_TYPE.ARRAY)
            new_commit = to!string(result_json[0]["sha"]);
            if(new_commit != old_commit) {
                writeln("[IntegrateD] Entering CI.");
                writeln("[IntegrateD] Old commit on "~
                    user_inputs.github_repo~
                    " is "~
                    old_commit);
                writeln("[IntegrateD] New commit on "~
                    user_inputs.github_repo~
                    " is "~
                    new_commit);
                old_commit = new_commit;
            }      
    }
}