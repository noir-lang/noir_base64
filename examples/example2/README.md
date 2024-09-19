# Example 2

For this example the correct values have already been added to `Prover.toml`. Execute the circuit:
```
nargo execute base64
```

Prove it, for example with default backend Barretenberg:
```
bb prove -b ./target/example2.json -w ./target/base64.gz -o ./target/proof
```

To verify, we need to export the verification key:

```bash
bb write_vk -b ./target/example2.json -o ./target/vk
```

And verify:

```bash
bb verify -k ./target/vk -p ./target/proof
```
If verification passed, you see nothing. Otherwise there is an error.