# Ambari-YARN-Configuration

A shell script to help you configure your Ambari Cluster automatically.

## Why this shell script needed?

**Apache Ambari** is one great project about **Hadoop eco-system**.

It can help users deploy their own **Hadoop Cluster** in a simple and easy way.

But, there still have one problem is about configurations.

In **Hadoop Cluster**, the confiqurations of **MapReduce** and **YARN** is quite annoying.

However, if you don't care this issue, your cluster can't be appropriate worked.

So, this script was created.


## How it worked?

The most important part is parameters of **MapReduce** and **YARN**.

This part I use another script - **yarn-utils.py** to figuire it out.

The **yarn-utils.py** is from [mahadevkonar](https://github.com/mahadevkonar/ambari-yarn-utils).

Thanks to the contribution from them.

And then, this script use **Ambari API** and **configs.sh** to configure **Ambari Cluster**.

You can find explanation and example at [here](https://cwiki.apache.org/confluence/display/AMBARI/API+usage+scenarios%2C+troubleshooting%2C+and+other+FAQs).


## How to use?

First, you need to clone this repository and put it on your **Ambari Server** for using **configs.sh**.

Then, you have to modify some setting in this script like:

1. User ID
2. Password
3. Port of **Ambari Server**
4. Address of **Ambari Server**

After all, use the command:

```
sh Ambari-YARN-Configuration.sh
```

Now, you can check your **Ambari Server** to verify the result.

*NOTES:* this script only restart your **MapReduce2** and **YARN**, if you already install other services which dependent **MapReduce2** and **YARN**, you need to restart it manually.



