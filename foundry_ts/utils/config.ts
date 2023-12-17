export let operation_map: Map<string, Function> = new Map();

// argv type is mapping from string to array of string
export let argv_type_config: {[key: string]: string[]} = {};

export function addOperation(method_name: string, func: Function) {
    operation_map.set(method_name, func);
}

export function addArgvType(typeStr: string, argName: string) {
    if (argv_type_config[typeStr] === undefined) {
        argv_type_config[typeStr] = [argName];
    } else if (argv_type_config[typeStr].indexOf(argName) === -1){
        argv_type_config[typeStr].push(argName);
    } else {
        console.log(`argName ${argName} is already in argv_type_config[${typeStr}]`);
    }
}