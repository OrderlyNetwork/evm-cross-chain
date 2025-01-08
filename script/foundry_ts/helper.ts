export function checkArgs(method_name: string, argv: any, flags: string[]) {
    let quit = false;

    let flag_string = "";

    // check for missing flags
    for (let flag of flags) {
        flag_string += `--${flag} <${flag}> `
        if (argv[flag] === undefined) {
            console.error(`Missing flag: ${flag}`);
            quit = true;
        }
    }

    if (quit) {
        console.error(`Usage: ts-node foundry_ts/entry.ts --method ${method_name} ${flag_string}`);
        process.exit(1);
    }

}
