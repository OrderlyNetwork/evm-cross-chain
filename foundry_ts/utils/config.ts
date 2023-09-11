export let operation_map: Map<string, Function> = new Map();

export function addOperation(method_name: string, func: Function) {
    operation_map.set(method_name, func);
}