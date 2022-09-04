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
    "/commits/master";
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
    github_response = "";
    new_commit = to!string(github_response_json["sha"]);
    new_commit_date = to!string(github_response_json["commit"]["author"]["date"]);
    if(new_commit != old_commit) {
      auto pid_garbage = execute(["pidof", user_inputs.kill_list]);
      if(pid_garbage.output!= null) {
        string pid_garbage_str = to!string(pid_garbage.output);
        pid_garbage_str = pid_garbage_str[0 .. pid_garbage_str.length - 1];
        auto pid_kill = execute(["kill", pid_garbage_str]);
        if (pid_kill.status != 0) writeln(pid_kill.output);
      }
      if(old_commit == "") {
        writeln("\033[1;33m[IntegrateD] Latest commit: "~
          user_inputs.github_repo ~ " is "~ new_commit ~ " time stamp is " ~ new_commit_date);
      } 
      else {
        writeln("\033[1;33m[IntegrateD] Old commit: "~
          user_inputs.github_repo~ " is "~ old_commit);
        writeln("\033[1;33m[IntegrateD] New commit: "~
          user_inputs.github_repo~ " is "~ new_commit ~ " time stamp is " ~ new_commit_date);                 
      }
      old_commit = new_commit;
      write("\033[1;32m\n");  
      auto pid_ci = spawnShell(
        user_inputs.ci_script,
        null,
        Config.none, 
        user_inputs.ci_path);  
    } // commit update   
  } // ci loop
} // main