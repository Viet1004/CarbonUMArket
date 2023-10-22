This project is done during the time of ETHglobal Online Hackathon

# CarbonUMArket

This project is based on the tutorial `https://docs.uma.xyz/developers/optimistic-oracle-v3/prediction-market`.

The goal is to create a transparent and verifiable Carbon Credit Market.

To do this we employ the `Optimistic Oracle V3` technology of `https://docs.uma.xyz/`

The structure of the market is composed of three parties.

The first one is the Issuer who issues the carbon market in exchange for money and reward for anyone auditing the market (In the simplest case, if anyone proves that they cannot deliver the number of carbon credits issued).

The second one is the Clients who want to buy some carbon credits.

The third one is the Validators who can audit the credits and get rewards if they can prove that the issuer doesn't fulfill their promise corresponding to the number of carbon credits emitted.

There are three market phases: 
1. Phase 0 - Opening market period: Clients can buy carbon credits. At that period, they could only buy convertible carbon credit.
2. Phase 1 - Auditing period: Validators audits the market and declares false promise if the issuer cannot fulfill their promise according to the number of carbon credits they emit
3. Phase 2 - Settling period: The clients and validators collect their credits and the reward.

During the opening market period, clients can buy some convertible carbon credits, which can be converted to carbon credits if, after phase 1, it is proved that the issuer fulfills their promise (absorb the promised number of carbon emissions).

During the auditing period: Validators can join together to add evidence if they find that the issuer cannot deliver promised carbon credits. If they do, they assert that statement to OOV3. If it is found that the assertion is truthful, they collect the reward, and the convertible carbon credits are burnt (lose their value). On the contrary, the assertion is not false, they don't get the reward and the issuer by default successfully delivers his/her promise. On the other hand, if they don't find the evidence, they do nothing, and by default, the issuer fulfills their promise.

During the settling period: If the issuer truthfully delivers their carbon credit, clients can exchange convertible carbon credits to actual carbon credits. If he/she don't, which is equivalent to the validators' assertion being verified,  can cash out the reward.

==========================================================

For this project, I intend to create a web app that interacts with the smart contract deployed in the scroll sepolia testnet but it is not finished.

To start the website, run `npm start`







