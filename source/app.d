// D
import std.array;
import std.conv;
import std.json;
import std.getopt;
import std.net.curl;
import std.process;
import std.stdio;

struct input {
  string 
    github_name = "", 
    github_repo = "",
    oauth_token = "",
    ci_path = "",
    ci_script = "",
    kill_list = "";
}

void main(string[] args) {
  input user_inputs;
  JSONValue github_response_json = null;
  string 
    new_commit = "", 
    old_commit = new_commit, 
    new_commit_date = "",
    github_response = "",
    http_call = "";
  write("\033[1;31m");
  if(args.length == 1) {
    writeln("No input arguments. Exiting IntegrateD.");
    return;
  } 
  auto helpInformation = getopt (
    args,
    "github_name", &user_inputs.github_name,
    "github_repo", &user_inputs.github_repo,    
    "oauth_token", &user_inputs.oauth_token,    
    "ci_path", &user_inputs.ci_path, 
    "ci_script", &user_inputs.ci_script,   
    "kill_list", &user_inputs.kill_list,
    config.stopOnFirstNonOption); 
  if ( user_inputs.ci_path == "" || user_inputs.ci_script == "" ) {
    writeln("CI path or CI script not given. Exiting IntegrateD.");
    return;
  }
  http_call = "https://api.github.com/repos/"~
    user_inputs.github_name~"/"~user_inputs.github_repo~
    "/commits";
  auto client = HTTP(http_call);
  client.addRequestHeader("Authorization", "token " ~ user_inputs.oauth_token);
  client.onReceive = (ubyte[] data) {
    github_response ~= cast(char[]) data; 
    return data.length;
  };
  writeln("\033[1;33m[IntegrateD] Http call: "~http_call);
  writeln("[IntegrateD] Script: " ~ user_inputs.ci_script);
  writeln("[Integrated] Shell path: " ~ user_inputs.ci_path);
  while(1) {
    client.perform();
    github_response_json = parseJSON(github_response);
    if(github_response_json.type == JSON_TYPE.ARRAY) {
      new_commit = to!string(github_response_json[0]["sha"]);
      new_commit_date = to!string(github_response_json[0]["commit"]["author"]["date"]);
      if(new_commit != old_commit) {
        auto pid_garbage = execute(["pidof", user_inputs.kill_list]);
        if(pid_garbage.output!= null) execute(["kill", pid_garbage.output]);
        if(old_commit == "") {
          writeln("[IntegrateD] Latest commit: "~
            user_inputs.github_repo ~ " is "~ new_commit ~ " time stamp is " ~ new_commit_date);
        } 
        else {
          writeln("[IntegrateD] Old commit: "~
            user_inputs.github_repo~ " is "~ old_commit);
          writeln("[IntegrateD] New commit: "~
            user_inputs.github_repo~ " is "~ new_commit ~ " time stamp is " ~ new_commit_date);                 
        }
        old_commit = new_commit;
        write("\033[1;32m\n");  
        auto pid_ci = spawnShell(
          user_inputs.ci_script,
          null,
          Config.none, 
          user_inputs.ci_path);  
        wait(pid_ci);                
        write("\033[1;37m\n");
      }      
    } // github response
  } // ci loop
} // main