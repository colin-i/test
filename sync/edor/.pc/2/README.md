# EDitOR
Use autoconf automake libncurses-dev ; on armv7l, libunwind-dev
```sh
autoreconf -i
./configure
make install
```
Or, for some 64-bit platforms:
```sh
make -f Makefile.old
```
Use *\-\-prefix=your_path* at *./configure* if needed (example: at Termux in Android).\
Uninstall command is *make uninstall*.\
*\-\-disable\-cpp* to set c rules.
###### Donations
| Name      | Address                                    |
|-----------|--------------------------------------------|
| Bitcoin   | 1DcXWYXpmopfgg3oZYWVBTLbDTmQ6nWG7s         |
| Ethereum  | 0xd8ea69f877b93fa663652bc2d944e71a338cd5f9 |
| Dogecoin  | DP28QjzNcWCF4XqdUoDcZ7DeWKhjTmZqY9         |
| Decred    | DsSdAMyVkKbX18fXK5pYJbNgXhfisc4onT9        |
| Digibyte  | DPK6t296EMSHNMzuoMyP2zbxRjtisaaCRu         |
| Ravencoin | RECqJbqzqNiGQeodcRSBqkAZjh2fbroUHL         |