// D
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
    client.perform();

    //writeln(result);
}